//! Rephraser Windows PoC — Phase 0 de-risk gate.
//!
//! Downloads Gemma 3 1B Q4_K_M GGUF, loads it via `llama-cpp-2`, streams a
//! rephrase prompt to stdout, and reports tokens/sec. CI asserts the Go/No-Go
//! gates from the plan:
//!   - Model loads (<1.5 GB RAM target — measured in Phase 3)
//!   - CPU streaming >= 3 tok/s on GitHub windows-latest runner
//!   - Non-empty output for a known prompt
//!
//! If this fails, switch stack to `mistral.rs` or `candle` before Phase 1.

#![allow(deprecated)] // some llama-cpp-2 methods are deprecated in 0.1.143 but still work

use anyhow::{Context, Result};
use clap::Parser;
use hf_hub::api::tokio::ApiBuilder;
use llama_cpp_2::{
    context::params::LlamaContextParams,
    llama_backend::LlamaBackend,
    llama_batch::LlamaBatch,
    model::{params::LlamaModelParams, AddBos, LlamaModel, Special},
    sampling::LlamaSampler,
};
use std::{num::NonZeroU32, path::PathBuf, time::Instant};
use tracing::{info, warn};

#[derive(Parser, Debug)]
#[command(author, version, about = "Rephraser Windows PoC — Phase 0 gate", long_about = None)]
struct Args {
    /// HuggingFace repo ID for the GGUF model.
    #[arg(long, default_value = "bartowski/gemma-3-1b-it-GGUF")]
    repo: String,

    /// Filename within the repo.
    #[arg(long, default_value = "gemma-3-1b-it-Q4_K_M.gguf")]
    filename: String,

    /// Prompt to rephrase (wrapped in the Rephraser "Professional" mode system prompt).
    #[arg(long, default_value = "hey can u send me the deck asap thx")]
    prompt: String,

    /// Max new tokens to generate.
    #[arg(long, default_value_t = 64)]
    max_tokens: i32,

    /// Optional local GGUF path (skips download — useful for local dev).
    #[arg(long)]
    local_model: Option<PathBuf>,
}

const SYSTEM_PROMPT: &str = "You are a writing assistant. Rewrite the user's text in a clear, professional tone. Preserve meaning and length. Output ONLY the rewritten text — no preamble, no quotes, no explanation.";

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .init();

    let args = Args::parse();

    // -------- Step 1: Obtain model --------
    let model_path = if let Some(path) = args.local_model.clone() {
        info!("Using local model: {}", path.display());
        path
    } else {
        info!("Downloading {} from {}", args.filename, args.repo);
        let api = ApiBuilder::new().with_progress(true).build()?;
        let repo = api.model(args.repo.clone());
        let path = repo
            .get(&args.filename)
            .await
            .with_context(|| format!("Failed to download {} from {}", args.filename, args.repo))?;
        info!("Model cached at: {}", path.display());
        path
    };

    let model_size = std::fs::metadata(&model_path)?.len();
    info!(
        "Model file size: {:.2} MB",
        model_size as f64 / 1024.0 / 1024.0
    );

    // -------- Step 2: Init backend + load model --------
    let t0 = Instant::now();
    let backend = LlamaBackend::init().context("Failed to init llama backend")?;

    let model_params = LlamaModelParams::default();
    let model = LlamaModel::load_from_file(&backend, &model_path, &model_params)
        .context("Failed to load GGUF model")?;
    info!("Model loaded in {:.2}s", t0.elapsed().as_secs_f32());

    // -------- Step 3: Build chat prompt (Gemma 3 format) --------
    // Gemma 3 chat template: <start_of_turn>user\n{system}\n\n{user}<end_of_turn>\n<start_of_turn>model\n
    let full_prompt = format!(
        "<start_of_turn>user\n{system}\n\n{user}<end_of_turn>\n<start_of_turn>model\n",
        system = SYSTEM_PROMPT,
        user = args.prompt
    );

    let tokens_in = model
        .str_to_token(&full_prompt, AddBos::Always)
        .context("Failed to tokenize prompt")?;
    info!("Input tokens: {}", tokens_in.len());

    // -------- Step 4: Create context --------
    let n_ctx = NonZeroU32::new(2048).unwrap();
    let ctx_params = LlamaContextParams::default()
        .with_n_ctx(Some(n_ctx))
        .with_n_batch(512);

    let mut ctx = model
        .new_context(&backend, ctx_params)
        .context("Failed to create llama context")?;

    // -------- Step 5: Prefill --------
    let mut batch = LlamaBatch::new(512, 1);
    let last_index = (tokens_in.len() - 1) as i32;
    for (i, token) in tokens_in.iter().enumerate() {
        let is_last = i as i32 == last_index;
        batch.add(*token, i as i32, &[0], is_last)?;
    }
    ctx.decode(&mut batch).context("Prefill decode failed")?;

    // -------- Step 6: Generate + stream (greedy sampler for determinism) --------
    let mut sampler = LlamaSampler::chain_simple([LlamaSampler::greedy()]);

    let mut n_cur = batch.n_tokens();
    let mut n_decode = 0;
    let t_gen_start = Instant::now();

    print!("\n=== OUTPUT ===\n");
    let mut full_output = String::new();

    while n_decode < args.max_tokens {
        let new_token = sampler.sample(&ctx, batch.n_tokens() - 1);
        sampler.accept(new_token);

        // EOS?
        if model.is_eog_token(new_token) {
            info!("EOS token reached");
            break;
        }

        let piece = model
            .token_to_str(new_token, Special::Tokenize)
            .unwrap_or_default();
        print!("{piece}");
        use std::io::Write;
        std::io::stdout().flush().ok();
        full_output.push_str(&piece);

        // Feed back for next step.
        batch.clear();
        batch.add(new_token, n_cur, &[0], true)?;

        n_cur += 1;
        n_decode += 1;
        ctx.decode(&mut batch).context("Decode step failed")?;
    }
    println!("\n=== /OUTPUT ===");

    let gen_secs = t_gen_start.elapsed().as_secs_f32();
    let tok_per_sec = n_decode as f32 / gen_secs;

    // -------- Step 7: Report --------
    info!("Generated {} tokens in {:.2}s", n_decode, gen_secs);
    info!("Tokens/sec: {:.2}", tok_per_sec);
    info!("Output length: {} chars", full_output.trim().len());

    // -------- Step 8: Assertions (Go/No-Go gates) --------
    let mut failures = Vec::new();
    if full_output.trim().is_empty() {
        failures.push("Empty output".to_string());
    }
    if tok_per_sec < 3.0 {
        failures.push(format!(
            "tok/s {:.2} < 3.0 (minimum for CPU inference)",
            tok_per_sec
        ));
    }

    if !failures.is_empty() {
        for f in &failures {
            warn!("GATE FAILURE: {}", f);
        }
        eprintln!("\n❌ Phase 0 GO/NO-GO gate FAILED. See warnings above.");
        std::process::exit(2);
    }

    println!("\n✅ Phase 0 GO/NO-GO gate PASSED.");
    println!("   - Model: {}", args.filename);
    println!("   - Output: {} chars", full_output.trim().len());
    println!("   - Speed: {:.2} tok/s", tok_per_sec);
    println!("\nNext: proceed to Phase 1 (Tauri skeleton).");

    Ok(())
}
