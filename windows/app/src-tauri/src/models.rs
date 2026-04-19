//! Model catalog + download manager.
//!
//! Phase 5 scope:
//!   - Read the compiled-in catalog from `shared/models/catalog.json`
//!   - Report installed models under `%LOCALAPPDATA%\Rephraser\models\`
//!   - Stream-download a GGUF from HuggingFace via `reqwest`, emitting
//!     `download://progress` events with {id, downloaded, total, pct}
//!   - Resumable downloads (plan A7): if a `.part` exists we send a
//!     `Range: bytes=<existing>-` header and append instead of restart
//!   - Atomic write via `.part` temp → rename on success
//!   - Disk-space precheck (plan A10/E10): abort if free < 2× model size
//!   - RAM precheck (plan A11): warn if total RAM < minRamGB for the model
//!   - SHA-256 verification (E14 supply chain): catalog entries carry an
//!     optional `sha256` field. If set, we hash the `.part` file after
//!     download completes and refuse to install on mismatch — the partial
//!     is deleted so the next retry starts clean. If blank, we fall back
//!     to TLS-only trust (v0.1 behaviour) and just log a warning.
//!   - Delete a model on request

use anyhow::{anyhow, Context, Result};
use futures_util::StreamExt;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::path::{Path, PathBuf};
use tauri::{AppHandle, Emitter, Manager};
use tokio::io::{AsyncReadExt, AsyncWriteExt};

// ---------- Catalog ----------

const CATALOG_JSON: &str = include_str!("../../../../shared/models/catalog.json");

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct CatalogEntry {
    pub id: String,
    #[serde(rename = "displayName")]
    pub display_name: String,
    pub description: String,
    pub repo: String,
    pub filename: String,
    /// Hex-encoded SHA-256 of the GGUF. Empty = verification skipped.
    #[serde(default)]
    pub sha256: String,
    #[serde(rename = "approxSizeMB")]
    pub approx_size_mb: u64,
    #[serde(rename = "minRamGB")]
    pub min_ram_gb: u64,
    #[serde(rename = "promptFormat")]
    pub prompt_format: String,
    pub gated: bool,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Catalog {
    pub version: u32,
    #[serde(rename = "defaultModelId")]
    pub default_model_id: String,
    pub models: Vec<CatalogEntry>,
}

pub fn catalog() -> &'static Catalog {
    use once_cell::sync::Lazy;
    static CATALOG: Lazy<Catalog> =
        Lazy::new(|| serde_json::from_str(CATALOG_JSON).expect("catalog.json malformed"));
    &CATALOG
}

// ---------- Paths ----------

pub fn models_dir(app: &AppHandle) -> Result<PathBuf> {
    let base = app
        .path()
        .local_data_dir()
        .context("no local_data_dir (LOCALAPPDATA on Windows)")?;
    let dir = base.join("Rephraser").join("models");
    std::fs::create_dir_all(&dir).ok();
    Ok(dir)
}

fn path_for(app: &AppHandle, entry: &CatalogEntry) -> Result<PathBuf> {
    Ok(models_dir(app)?.join(&entry.filename))
}

// ---------- Installed ----------

#[derive(Debug, Clone, Serialize)]
pub struct InstalledModel {
    pub id: String,
    pub path: String,
    pub size_bytes: u64,
}

pub fn list_installed(app: &AppHandle) -> Result<Vec<InstalledModel>> {
    let cat = catalog();
    let mut out = Vec::new();
    for e in &cat.models {
        let p = path_for(app, e)?;
        if p.exists() {
            let size = std::fs::metadata(&p).map(|m| m.len()).unwrap_or(0);
            out.push(InstalledModel {
                id: e.id.clone(),
                path: p.to_string_lossy().into_owned(),
                size_bytes: size,
            });
        }
    }
    Ok(out)
}

// ---------- Download ----------

#[derive(Debug, Clone, Serialize)]
pub struct ProgressEvent {
    pub id: String,
    pub downloaded: u64,
    pub total: u64,
    pub pct: f32,
}

fn hf_resolve_url(repo: &str, filename: &str) -> String {
    format!("https://huggingface.co/{repo}/resolve/main/{filename}?download=true")
}

/// Rough disk-space check: ensure at least 2× the model size is free on the
/// volume that will host `target`. Best-effort — if the check itself fails
/// we proceed (don't block on platform quirks).
fn precheck_disk(target: &Path, min_bytes: u64) -> Result<()> {
    // Walk up to the nearest existing ancestor so `available_space` can stat.
    let mut probe = target.to_path_buf();
    while !probe.exists() {
        if !probe.pop() {
            return Ok(());
        }
    }
    match fs2_available_space(&probe) {
        Some(free) if free < min_bytes => Err(anyhow!(
            "not enough free disk: have {} MB, need {} MB",
            free / 1_048_576,
            min_bytes / 1_048_576
        )),
        _ => Ok(()),
    }
}

// Avoid pulling `fs2` as a dep for a single call — use the `windows` crate
// on Windows, and fall back to `None` elsewhere (CI only cares on Windows).
#[cfg(windows)]
fn fs2_available_space(path: &Path) -> Option<u64> {
    use std::os::windows::ffi::OsStrExt;
    use windows::core::PCWSTR;
    use windows::Win32::Storage::FileSystem::GetDiskFreeSpaceExW;
    let wide: Vec<u16> = path
        .as_os_str()
        .encode_wide()
        .chain(std::iter::once(0))
        .collect();
    let mut free_bytes_avail: u64 = 0;
    unsafe {
        if GetDiskFreeSpaceExW(
            PCWSTR(wide.as_ptr()),
            Some(&mut free_bytes_avail),
            None,
            None,
        )
        .is_ok()
        {
            Some(free_bytes_avail)
        } else {
            None
        }
    }
}

#[cfg(not(windows))]
fn fs2_available_space(_path: &Path) -> Option<u64> {
    None
}

/// Total physical RAM in bytes (plan A11). `None` on non-Windows or if the
/// syscall fails — callers treat that as "skip the check".
#[cfg(windows)]
fn total_ram_bytes() -> Option<u64> {
    use windows::Win32::System::SystemInformation::{GlobalMemoryStatusEx, MEMORYSTATUSEX};
    let mut status: MEMORYSTATUSEX = unsafe { std::mem::zeroed() };
    status.dwLength = std::mem::size_of::<MEMORYSTATUSEX>() as u32;
    unsafe {
        GlobalMemoryStatusEx(&mut status).ok()?;
    }
    Some(status.ullTotalPhys)
}

#[cfg(not(windows))]
fn total_ram_bytes() -> Option<u64> {
    None
}

pub async fn download(app: AppHandle, id: String) -> Result<PathBuf> {
    let entry = catalog()
        .models
        .iter()
        .find(|e| e.id == id)
        .ok_or_else(|| anyhow!("unknown model id: {id}"))?
        .clone();

    let target = path_for(&app, &entry)?;
    if target.exists() {
        return Ok(target);
    }

    let min_bytes = entry.approx_size_mb * 1024 * 1024 * 2;
    precheck_disk(&target, min_bytes)?;

    // A11 — warn (via log + event) if total physical RAM is below the
    // model's minRamGB. We don't hard-block: users may have swap, or the
    // catalog value may be conservative. The frontend can surface the
    // `download://low-ram` event as a non-blocking toast.
    if let Some(total_ram) = total_ram_bytes() {
        let need = entry.min_ram_gb.saturating_mul(1024 * 1024 * 1024);
        if total_ram < need {
            tracing::warn!(
                "low RAM for {}: have {} MB, model wants {} GB",
                entry.id,
                total_ram / 1_048_576,
                entry.min_ram_gb
            );
            let _ = app.emit(
                "download://low-ram",
                serde_json::json!({
                    "id": entry.id,
                    "totalRamMB": total_ram / 1_048_576,
                    "minRamGB": entry.min_ram_gb,
                }),
            );
        }
    }

    // A7 — resumable download. If a `.part` file already exists, append
    // to it and ask HF for the rest via `Range:`. Otherwise start fresh.
    let tmp = target.with_extension("part");
    let existing: u64 = tokio::fs::metadata(&tmp)
        .await
        .map(|m| m.len())
        .unwrap_or(0);

    let url = hf_resolve_url(&entry.repo, &entry.filename);
    let client = reqwest::Client::builder()
        .user_agent("Rephraser-Windows/0.1")
        .build()
        .context("build reqwest client")?;

    let mut req = client.get(&url);
    if existing > 0 {
        req = req.header("Range", format!("bytes={}-", existing));
        tracing::info!("resuming {} from byte {}", entry.id, existing);
    }

    let resp = req
        .send()
        .await
        .context("GET model file")?
        .error_for_status()
        .with_context(|| format!("bad HTTP status from {url}"))?;

    // If server ignored Range (200 instead of 206), restart from zero.
    let resuming = existing > 0 && resp.status().as_u16() == 206;
    let mut downloaded: u64 = if resuming { existing } else { 0 };
    let body_len = resp.content_length().unwrap_or(0);
    let total = if resuming { existing + body_len } else { body_len };

    let mut file = if resuming {
        tokio::fs::OpenOptions::new()
            .append(true)
            .open(&tmp)
            .await
            .context("open .part for append")?
    } else {
        tokio::fs::File::create(&tmp)
            .await
            .context("create .part file")?
    };

    let mut stream = resp.bytes_stream();
    let mut last_pct: i32 = -1;

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.context("stream chunk")?;
        file.write_all(&chunk).await.context("write chunk")?;
        downloaded += chunk.len() as u64;
        let pct = if total > 0 {
            (downloaded as f32 / total as f32 * 100.0) as i32
        } else {
            -1
        };
        // Throttle to whole-% ticks; saves event spam on big downloads.
        if pct != last_pct {
            last_pct = pct;
            let _ = app.emit(
                "download://progress",
                ProgressEvent {
                    id: id.clone(),
                    downloaded,
                    total,
                    pct: pct as f32,
                },
            );
        }
    }

    file.flush().await.ok();
    drop(file);

    // SHA-256 verification before rename. If the catalog pins a digest, we
    // refuse to install on mismatch and nuke the .part so retries start
    // clean. Empty digest = fall back to TLS trust (v0.1) and just log.
    if !entry.sha256.is_empty() {
        let actual = sha256_file(&tmp).await.context("hash downloaded file")?;
        let expected = entry.sha256.to_ascii_lowercase();
        if actual != expected {
            let _ = tokio::fs::remove_file(&tmp).await;
            return Err(anyhow!(
                "SHA-256 mismatch for {}: expected {}, got {}. File deleted; retry the download.",
                entry.id,
                expected,
                actual
            ));
        }
        tracing::info!("SHA-256 verified for {}: {}", entry.id, actual);
    } else {
        tracing::warn!(
            "no SHA-256 pin for {} — trusting TLS only (see shared/models/catalog.json)",
            entry.id
        );
    }

    tokio::fs::rename(&tmp, &target)
        .await
        .with_context(|| format!("rename {:?} -> {:?}", tmp, target))?;
    Ok(target)
}

/// Stream a file through SHA-256 in 1 MiB chunks (avoids loading 2+ GB
/// GGUFs into RAM for hashing).
async fn sha256_file(path: &Path) -> Result<String> {
    let mut f = tokio::fs::File::open(path)
        .await
        .with_context(|| format!("open {:?} for hashing", path))?;
    let mut hasher = Sha256::new();
    let mut buf = vec![0u8; 1024 * 1024];
    loop {
        let n = f.read(&mut buf).await.context("read for hashing")?;
        if n == 0 {
            break;
        }
        hasher.update(&buf[..n]);
    }
    Ok(format!("{:x}", hasher.finalize()))
}

pub fn delete(app: &AppHandle, id: &str) -> Result<()> {
    let entry = catalog()
        .models
        .iter()
        .find(|e| e.id == id)
        .ok_or_else(|| anyhow!("unknown model id: {id}"))?;
    let p = path_for(app, entry)?;
    if p.exists() {
        std::fs::remove_file(&p).with_context(|| format!("delete {:?}", p))?;
    }
    Ok(())
}

/// Convenience: look up the local path for an installed model (or None).
#[allow(dead_code)] // wired up in Phase 6 (settings → auto-load selected model)
pub fn installed_path(app: &AppHandle, id: &str) -> Option<PathBuf> {
    let entry = catalog().models.iter().find(|e| e.id == id)?;
    let p = path_for(app, entry).ok()?;
    p.exists().then_some(p)
}
