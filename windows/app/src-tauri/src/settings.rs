//! Disk-backed settings for Rephraser.
//!
//! Plain JSON at `%LOCALAPPDATA%\Rephraser\settings.json`. Kept in Rust
//! (not `tauri-plugin-store`) so analytics + startup code can read the
//! flags without a JS round-trip. Settings.tsx reads the same file via
//! the `get_settings` / `update_settings` commands.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(default)]
pub struct Settings {
    pub hotkey: String,
    #[serde(rename = "selectedModelID")]
    pub selected_model_id: Option<String>,
    #[serde(rename = "analyticsEnabled")]
    pub analytics_enabled: bool,
    #[serde(rename = "launchAtLogin")]
    pub launch_at_login: bool,
    /// Opaque anonymous id for TelemetryDeck. Generated on first launch.
    #[serde(rename = "anonymousId")]
    pub anonymous_id: Option<String>,
    #[serde(rename = "schemaVersion")]
    pub schema_version: u32,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            hotkey: "Ctrl+Alt+R".to_string(),
            selected_model_id: None,
            analytics_enabled: true,
            launch_at_login: false,
            anonymous_id: None,
            schema_version: 1,
        }
    }
}

fn settings_path(app: &AppHandle) -> Result<PathBuf> {
    let base = app
        .path()
        .local_data_dir()
        .context("no local_data_dir")?;
    let dir = base.join("Rephraser");
    std::fs::create_dir_all(&dir).ok();
    Ok(dir.join("settings.json"))
}

pub fn load(app: &AppHandle) -> Settings {
    let path = match settings_path(app) {
        Ok(p) => p,
        Err(_) => return Settings::default(),
    };
    if !path.exists() {
        return Settings::default();
    }
    match std::fs::read_to_string(&path) {
        Ok(raw) => match serde_json::from_str::<Settings>(&raw) {
            Ok(s) => s,
            Err(e) => {
                tracing::warn!("settings.json corrupt ({e}); backing up and using defaults");
                let bak = path.with_extension(format!(
                    "json.bak.{}",
                    std::time::SystemTime::now()
                        .duration_since(std::time::UNIX_EPOCH)
                        .map(|d| d.as_secs())
                        .unwrap_or(0)
                ));
                let _ = std::fs::rename(&path, &bak);
                Settings::default()
            }
        },
        Err(_) => Settings::default(),
    }
}

pub fn save(app: &AppHandle, settings: &Settings) -> Result<()> {
    let path = settings_path(app)?;
    let tmp = path.with_extension("json.tmp");
    std::fs::write(&tmp, serde_json::to_vec_pretty(settings)?)?;
    std::fs::rename(&tmp, &path)?;
    Ok(())
}

/// Ensure the anonymous id exists; returns the sha256-hex of it (what
/// TelemetryDeck wants for `clientUser`).
pub fn ensure_anonymous_client_hash(app: &AppHandle) -> Option<String> {
    let mut s = load(app);
    if s.anonymous_id.is_none() {
        // Fallback-free UUID v4 from the system CSPRNG.
        let mut bytes = [0u8; 16];
        if getrandom::getrandom(&mut bytes).is_err() {
            return None;
        }
        // Set version (4) and variant (RFC 4122).
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
        bytes[8] = (bytes[8] & 0x3f) | 0x80;
        let hex: String = bytes.iter().map(|b| format!("{b:02x}")).collect();
        s.anonymous_id = Some(hex);
        let _ = save(app, &s);
    }
    let id = s.anonymous_id.as_ref()?;
    use sha2::{Digest, Sha256};
    let digest = Sha256::digest(id.as_bytes());
    Some(digest.iter().map(|b| format!("{b:02x}")).collect())
}
