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

/// Synthesize Ctrl+V to paste the current clipboard at the caret.
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
