//! Floating rephrase panel — frameless, transparent, always-on-top.
//!
//! Mirrors Mac's `RephrasePanel.swift`. Rust creates or reuses a single
//! WebView window at `index.html?view=panel`, then emits `panel://open`
//! so the React side can render with the captured source text + suggested
//! mode and kick off streaming inference.

use anyhow::Result;
use serde::Serialize;
use tauri::{AppHandle, Emitter, LogicalSize, Manager, WebviewUrl, WebviewWindowBuilder};

const PANEL_LABEL: &str = "rephrase-panel";
const PANEL_W: f64 = 560.0;
const PANEL_H: f64 = 320.0;

#[derive(Debug, Clone, Serialize)]
pub struct OpenPayload {
    pub text: String,
    pub previous_clipboard: Option<String>,
    pub suggested_mode: String,
}

/// Show or create the panel window, then emit `panel://open`.
pub fn show_panel(app: &AppHandle, payload: OpenPayload) -> Result<()> {
    if let Some(win) = app.get_webview_window(PANEL_LABEL) {
        let _ = win.show();
        let _ = win.set_focus();
    } else {
        let url = WebviewUrl::App("index.html?view=panel".into());
        let _ = WebviewWindowBuilder::new(app, PANEL_LABEL, url)
            .title("Rephraser")
            .inner_size(PANEL_W, PANEL_H)
            .min_inner_size(420.0, 240.0)
            .decorations(false)
            .transparent(true)
            .always_on_top(true)
            .skip_taskbar(true)
            .resizable(true)
            .focused(true)
            .build()?;
    }

    // Keep panel a sensible size in case a stale window was minimized.
    if let Some(win) = app.get_webview_window(PANEL_LABEL) {
        let _ = win.set_size(LogicalSize::new(PANEL_W, PANEL_H));
    }

    // Give the webview a tick to wire up its `listen()` subscription before
    // we fire the open event; 50 ms is well under human perception.
    let app_clone = app.clone();
    std::thread::spawn(move || {
        std::thread::sleep(std::time::Duration::from_millis(50));
        if let Err(e) = app_clone.emit("panel://open", payload) {
            tracing::warn!("Failed to emit panel://open: {e}");
        }
    });

    Ok(())
}

/// Close the panel window if it exists.
pub fn close_panel(app: &AppHandle) {
    if let Some(win) = app.get_webview_window(PANEL_LABEL) {
        let _ = win.close();
    }
}
