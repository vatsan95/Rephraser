//! Clipboard snapshot + synthetic copy/paste.
//!
//! Mirrors Mac's `TextCaptureService`:
//! 1. Snapshot clipboard text → memory
//! 2. Synthesize Ctrl+C
//! 3. Poll up to 200 ms for a changed clipboard text
//! 4. Restore original clipboard after rephrase (on accept: paste then restore;
//!    on dismiss: restore immediately)
//!
//! Phase 2 lands the primitives; Phase 3/4 wires them to inference + panel.

use anyhow::{anyhow, Context, Result};
use arboard::Clipboard;
use enigo::{Direction, Enigo, Key, Keyboard, Settings};
use std::thread;
use std::time::{Duration, Instant};

const POLL_TIMEOUT: Duration = Duration::from_millis(200);
const POLL_INTERVAL: Duration = Duration::from_millis(10);

/// Snapshot the current clipboard text (None if non-text / empty).
pub fn snapshot() -> Option<String> {
    Clipboard::new().ok()?.get_text().ok()
}

/// Write text to the clipboard.
#[allow(dead_code)] // wired up in Phase 3 (accept/dismiss flow)
pub fn restore(text: &str) -> Result<()> {
    Clipboard::new()
        .context("Failed to open clipboard")?
        .set_text(text.to_string())
        .context("Failed to write clipboard")
}

/// Synthesize Ctrl+C, then poll until the clipboard text changes or times out.
/// Returns the new clipboard text (the user's selection).
pub fn capture_selection(previous: Option<&str>) -> Result<String> {
    let mut enigo = Enigo::new(&Settings::default()).context("Failed to init enigo")?;
    enigo
        .key(Key::Control, Direction::Press)
        .map_err(|e| anyhow!("ctrl press failed: {e:?}"))?;
    enigo
        .key(Key::Unicode('c'), Direction::Click)
        .map_err(|e| anyhow!("c click failed: {e:?}"))?;
    enigo
        .key(Key::Control, Direction::Release)
        .map_err(|e| anyhow!("ctrl release failed: {e:?}"))?;

    let start = Instant::now();
    while start.elapsed() < POLL_TIMEOUT {
        thread::sleep(POLL_INTERVAL);
        if let Some(current) = snapshot() {
            if Some(current.as_str()) != previous {
                return Ok(current);
            }
        }
    }
    Err(anyhow!("No selection captured within {POLL_TIMEOUT:?}"))
}

/// RAII guard: snapshots the clipboard on construction and restores it on
/// `Drop` unless `disarm()` is called. Ensures that a panic anywhere between
/// capture and accept/dismiss doesn't strand the user's original clipboard
/// contents. Mirrors Mac's `defer { restoreClipboard() }`.
#[allow(dead_code)] // wired up by callers that want panic-safe restore
pub struct ClipboardGuard {
    saved: Option<String>,
    armed: bool,
}

#[allow(dead_code)]
impl ClipboardGuard {
    pub fn snapshot_now() -> Self {
        Self {
            saved: snapshot(),
            armed: true,
        }
    }

    pub fn saved(&self) -> Option<&str> {
        self.saved.as_deref()
    }

    /// Caller has taken responsibility for clipboard state — don't restore
    /// on drop. Use this after a successful accept-flow where the final
    /// clipboard value is intentional.
    pub fn disarm(mut self) {
        self.armed = false;
    }
}

impl Drop for ClipboardGuard {
    fn drop(&mut self) {
        if !self.armed {
            return;
        }
        if let Some(text) = &self.saved {
            // Best-effort; nothing meaningful we can do on failure during
            // an unwind or normal drop.
            let _ = Clipboard::new().and_then(|mut c| c.set_text(text.clone()));
        }
    }
}

/// Synthesize Ctrl+V to paste the current clipboard at the caret.
#[allow(dead_code)] // wired up in Phase 4 (panel accept)
pub fn synth_paste() -> Result<()> {
    let mut enigo = Enigo::new(&Settings::default()).context("Failed to init enigo")?;
    enigo
        .key(Key::Control, Direction::Press)
        .map_err(|e| anyhow!("ctrl press failed: {e:?}"))?;
    enigo
        .key(Key::Unicode('v'), Direction::Click)
        .map_err(|e| anyhow!("v click failed: {e:?}"))?;
    enigo
        .key(Key::Control, Direction::Release)
        .map_err(|e| anyhow!("ctrl release failed: {e:?}"))?;
    Ok(())
}
