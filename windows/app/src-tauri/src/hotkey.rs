//! Global hotkey registration (Ctrl+Alt+R by default).
//!
//! `GlobalHotKeyManager` on Windows holds a raw HWND — not Send/Sync — so we
//! park it inside the listener thread for the program's lifetime instead of a
//! static. Dropping the manager would drop the registration, so the thread
//! deliberately never returns.

use anyhow::Result;
use global_hotkey::{
    hotkey::{Code, HotKey, Modifiers},
    GlobalHotKeyEvent, GlobalHotKeyManager,
};
use tauri::{AppHandle, Emitter};

pub fn init(app: &AppHandle) -> Result<()> {
    let app_handle = app.clone();
    std::thread::spawn(move || {
        let manager = match GlobalHotKeyManager::new() {
            Ok(m) => m,
            Err(e) => {
                tracing::warn!("Failed to create global hotkey manager: {e}");
                return;
            }
        };
        // Default: Ctrl+Alt+R (user-configurable in Phase 6)
        let hotkey = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::KeyR);
        if let Err(e) = manager.register(hotkey) {
            tracing::warn!("Failed to register Ctrl+Alt+R: {e}");
            return;
        }
        tracing::info!("Hotkey registered: Ctrl+Alt+R");

        let receiver = GlobalHotKeyEvent::receiver();
        loop {
            match receiver.recv() {
                Ok(event) => {
                    if event.state == global_hotkey::HotKeyState::Pressed {
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
        // Manager drops here only if the receiver closes — in practice, never.
        drop(manager);
    });
    Ok(())
}
