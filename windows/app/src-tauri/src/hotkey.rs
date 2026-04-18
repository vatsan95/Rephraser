//! Global hotkey registration (Ctrl+Alt+R by default).
//!
//! Uses the `global-hotkey` crate which integrates with Tauri's event loop on
//! Windows. When fired, emits a Tauri event (`hotkey://pressed`) that the rest
//! of the app listens for — Phase 3 hooks inference here, Phase 4 shows the panel.

use anyhow::{Context, Result};
use global_hotkey::{
    hotkey::{Code, HotKey, Modifiers},
    GlobalHotKeyEvent, GlobalHotKeyManager,
};
use std::sync::OnceLock;
use tauri::{AppHandle, Emitter};

static MANAGER: OnceLock<GlobalHotKeyManager> = OnceLock::new();

/// Register the default hotkey and start listening for presses.
/// Spawns a tokio task that bridges global-hotkey events into Tauri events.
pub fn init(app: &AppHandle) -> Result<()> {
    let manager = GlobalHotKeyManager::new().context("Failed to create hotkey manager")?;

    // Default: Ctrl+Alt+R (matches Mac ⌥⇧R conceptually — user-configurable in Phase 6)
    let hotkey = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::KeyR);
    manager
        .register(hotkey)
        .context("Failed to register global hotkey Ctrl+Alt+R")?;

    let _ = MANAGER.set(manager);

    // Bridge global-hotkey channel → Tauri event bus
    let app_handle = app.clone();
    std::thread::spawn(move || {
        let receiver = GlobalHotKeyEvent::receiver();
        loop {
            match receiver.recv() {
                Ok(event) => {
                    if event.state == global_hotkey::HotKeyState::Pressed {
                        tracing::info!("Global hotkey pressed (id={})", event.id);
                        if let Err(e) = app_handle.emit("hotkey://pressed", ()) {
                            tracing::warn!("Failed to emit hotkey event: {e}");
                        }
                    }
                }
                Err(e) => {
                    tracing::warn!("Hotkey channel closed: {e}");
                    break;
                }
            }
        }
    });

    tracing::info!("Hotkey registered: Ctrl+Alt+R");
    Ok(())
}
