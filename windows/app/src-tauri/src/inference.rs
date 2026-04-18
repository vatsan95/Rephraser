//! On-device inference via llama-cpp-2 (ported from windows/poc/src/main.rs).
//!
//! Phase 3 scope:
//!   - Load a GGUF model from a local path (download is Phase 5).
//!   - Run a greedy rephrase given (text, mode_id), streaming tokens to the
//!     frontend via `rephrase://token` Tauri events and ending with
//!     `rephrase://done` (with `error` field on failure).
//!
//! Design:
//!   - `LlamaBackend` + `LlamaModel` live in a process-wide `OnceCell`, behind
//!     a `tokio::sync::Mutex` so `load_model` is idempotent and swap-safe.
//!   - `LlamaContext` is created fresh per rephrase inside `spawn_blocking` —
//!     it holds raw pointers and is !Send, so it never crosses threads.
//!   - Prompt format is ChatML (Qwen2.5 compatible); revisit per-model in
//!     Phase 5 when the catalog lands.

#![allow(deprecated)] // `token_to_str` + `Special::Tokenize` deprecated in 0.1.143 but still work

use anyhow::{anyhow, Context, Result};
use llama_cpp_2::{
    context::params::LlamaContextParams,
    llama_backend::LlamaBackend,
    llama_batch::LlamaBatch,
    model::{params::LlamaModelParams, AddBos, LlamaModel, Special},
    sampling::LlamaSampler,
};
use once_cell::sync::Lazy;
use serde::{Deserialize, Serialize};
use std::{num::NonZeroU32, path::PathBuf, sync::Arc};
use tauri::{AppHandle, Emitter};
use tokio::sync::Mutex;

// ---------- Mode catalog (shared with Mac) ----------

const MODES_JSON: &str = include_str!("../../../../shared/prompts/modes.json");

#[derive(Debug, Clone, Deserialize)]
struct ModeDef {
    id: String,
    #[serde(rename = "systemPrompt")]
    system_prompt: String,
}

#[derive(Debug, Clone, Deserialize)]
struct ModeCatalog {
    modes: Vec<ModeDef>,
}

static MODES: Lazy<Vec<ModeDef>> = Lazy::new(|| {
    serde_json::from_str::<ModeCatalog>(MODES_JSON)
        .expect("shared/prompts/modes.json is malformed")
        .modes
});

fn system_prompt_for(mode_id: &str) -> Option<&'static str> {
    MODES
        .iter()
        .find(|m| m.id == mode_id)
        .map(|m| m.system_prompt.as_str())
}

// ---------- Backend + model singleton ----------

struct LoadedModel {
    backend: LlamaBackend,
    model: LlamaModel,
    path: PathBuf,
}

// LlamaBackend + LlamaModel are Send+Sync in llama-cpp-2; the !Send
// LlamaContext is recreated per-request inside spawn_blocking.
static LOADED: Lazy<Arc<Mutex<Option<LoadedModel>>>> = Lazy::new(|| Arc::new(Mutex::new(None)));

/// Load a GGUF model from disk. Safe to call repeatedly; later calls swap.
pub async fn load_model(path: PathBuf) -> Result<()> {
    if !path.exists() {
        return Err(anyhow!("Model not found: {}", path.display()));
    }
    let p = path.clone();
    let loaded = tokio::task::spawn_blocking(move || -> Result<LoadedModel> {
        let backend = LlamaBackend::init().context("init llama backend")?;
        let model_params = LlamaModelParams::default();
        let model = LlamaModel::load_from_file(&backend, &p, &model_params)
            .context("load GGUF model")?;
        Ok(LoadedModel {
            backend,
            model,
            path: p,
        })
    })
    .await
    .context("join load_model blocking task")??;

    let mut guard = LOADED.lock().await;
    tracing::info!("Model loaded: {}", loaded.path.display());
    *guard = Some(loaded);
    Ok(())
}

// ---------- Streaming rephrase ----------

#[derive(Debug, Serialize, Clone)]
pub struct TokenEvent {
    pub text: String,
    pub index: u32,
}

#[derive(Debug, Serialize, Clone)]
pub struct DoneEvent {
    pub total_tokens: u32,
    pub duration_ms: u128,
    pub tok_per_sec: f32,
    pub error: Option<String>,
}

const MAX_NEW_TOKENS: i32 = 384;

/// Stream a rephrase for `text` in `mode_id` — emits events on `app`:
///   - `rephrase://token` (TokenEvent) for every generated piece
///   - `rephrase://done`  (DoneEvent) once, with optional error
pub async fn rephrase(app: AppHandle, text: String, mode_id: String) -> Result<()> {
    let system = system_prompt_for(&mode_id)
        .ok_or_else(|| anyhow!("unknown mode: {mode_id}"))?
        .to_string();

    let loaded_arc = LOADED.clone();
    let app_clone = app.clone();

    let start = std::time::Instant::now();
    let result: Result<u32> = tokio::task::spawn_blocking(move || -> Result<u32> {
        let rt = tokio::runtime::Handle::try_current();
        // We're inside spawn_blocking — need to block to acquire the async mutex.
        let guard = match rt {
            Ok(handle) => handle.block_on(loaded_arc.lock()),
            Err(_) => return Err(anyhow!("no tokio runtime in blocking task")),
        };
        let loaded = guard.as_ref().ok_or_else(|| anyhow!("no model loaded"))?;
        let backend = &loaded.backend;
        let model = &loaded.model;

        // ChatML prompt.
        let full_prompt = format!(
            "<|im_start|>system\n{system}<|im_end|>\n<|im_start|>user\n{user}<|im_end|>\n<|im_start|>assistant\n",
            user = text
        );
        let tokens_in = model
            .str_to_token(&full_prompt, AddBos::Always)
            .context("tokenize prompt")?;

        let n_ctx = NonZeroU32::new(2048).unwrap();
        let ctx_params = LlamaContextParams::default()
            .with_n_ctx(Some(n_ctx))
            .with_n_batch(512);
        let mut ctx = model
            .new_context(backend, ctx_params)
            .context("create llama context")?;

        // Prefill.
        let mut batch = LlamaBatch::new(512, 1);
        let last_index = (tokens_in.len() - 1) as i32;
        for (i, token) in tokens_in.iter().enumerate() {
            let is_last = i as i32 == last_index;
            batch.add(*token, i as i32, &[0], is_last)?;
        }
        ctx.decode(&mut batch).context("prefill decode")?;

        // Greedy streaming.
        let mut sampler = LlamaSampler::chain_simple([LlamaSampler::greedy()]);
        let mut n_cur = batch.n_tokens();
        let mut n_decode: u32 = 0;

        while (n_decode as i32) < MAX_NEW_TOKENS {
            let new_token = sampler.sample(&ctx, batch.n_tokens() - 1);
            sampler.accept(new_token);

            if model.is_eog_token(new_token) {
                break;
            }

            let piece = model
                .token_to_str(new_token, Special::Tokenize)
                .unwrap_or_default();

            if !piece.is_empty() {
                let _ = app_clone.emit(
                    "rephrase://token",
                    TokenEvent {
                        text: piece,
                        index: n_decode,
                    },
                );
            }

            batch.clear();
            batch.add(new_token, n_cur, &[0], true)?;
            n_cur += 1;
            n_decode += 1;
            ctx.decode(&mut batch).context("decode step")?;
        }

        Ok(n_decode)
    })
    .await
    .context("join rephrase blocking task")?;

    let dur = start.elapsed();
    let done = match &result {
        Ok(n) => DoneEvent {
            total_tokens: *n,
            duration_ms: dur.as_millis(),
            tok_per_sec: *n as f32 / dur.as_secs_f32().max(0.001),
            error: None,
        },
        Err(e) => DoneEvent {
            total_tokens: 0,
            duration_ms: dur.as_millis(),
            tok_per_sec: 0.0,
            error: Some(e.to_string()),
        },
    };
    let _ = app.emit("rephrase://done", done);

    result.map(|_| ())
}

/// True once a model is resident in memory.
pub async fn is_loaded() -> bool {
    LOADED.lock().await.is_some()
}
