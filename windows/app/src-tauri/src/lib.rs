//! Rephraser for Windows — Phase 1 skeleton + Phase 2 hotkey/clipboard.

mod clipboard;
mod context;
mod hotkey;
mod inference;

use tauri::{
    menu::{Menu, MenuItem},
    tray::TrayIconBuilder,
    Manager,
};

#[tauri::command]
fn ping() -> &'static str {
    "pong"
}

/// Command invoked from the hotkey event bridge (or frontend for testing).
/// Snapshots clipboard, synthesizes Ctrl+C, returns the captured selection.
/// Phase 3 will chain this into inference.
#[tauri::command]
async fn capture_selection() -> Result<serde_json::Value, String> {
    let previous = clipboard::snapshot();
    let captured = clipboard::capture_selection(previous.as_deref()).map_err(|e| e.to_string())?;
    let process = context::foreground_process_name().unwrap_or_default();
    let mode = context::mode_for_process(&process);

    Ok(serde_json::json!({
        "text": captured,
        "previous_clipboard": previous,
        "source_process": process,
        "suggested_mode": mode,
    }))
}

/// Phase 3: load a GGUF model from disk (download flow lands in Phase 5).
#[tauri::command]
async fn load_model(path: String) -> Result<(), String> {
    inference::load_model(std::path::PathBuf::from(path))
        .await
        .map_err(|e| e.to_string())
}

/// Phase 3: is a model currently loaded in memory?
#[tauri::command]
async fn is_model_loaded() -> bool {
    inference::is_loaded().await
}

/// Phase 3: stream a rephrase — emits `rephrase://token` + `rephrase://done`.
#[tauri::command]
async fn rephrase(app: tauri::AppHandle, text: String, mode: String) -> Result<(), String> {
    inference::rephrase(app, text, mode)
        .await
        .map_err(|e| e.to_string())
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_single_instance::init(|app, _argv, _cwd| {
            if let Some(window) = app.get_webview_window("main") {
                let _ = window.unminimize();
                let _ = window.set_focus();
            }
        }))
        .plugin(tauri_plugin_log::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_store::Builder::default().build())
        // updater plugin ships in Phase 6 with signing keys
        .plugin(tauri_plugin_autostart::init(
            tauri_plugin_autostart::MacosLauncher::LaunchAgent,
            None,
        ))
        .setup(|app| {
            // System tray (Phase 1)
            let quit_item = MenuItem::with_id(app, "quit", "Quit Rephraser", true, None::<&str>)?;
            let about_item =
                MenuItem::with_id(app, "about", "About Rephraser", true, None::<&str>)?;
            let menu = Menu::with_items(app, &[&about_item, &quit_item])?;

            let _tray = TrayIconBuilder::with_id("main-tray")
                .tooltip("Rephraser")
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .on_menu_event(|app, event| match event.id.as_ref() {
                    "quit" => {
                        app.exit(0);
                    }
                    "about" => {
                        tracing::info!("About clicked (panel not yet implemented)");
                    }
                    _ => {}
                })
                .build(app)?;

            // Global hotkey (Phase 2)
            if let Err(e) = hotkey::init(&app.handle().clone()) {
                tracing::warn!("Failed to init hotkey: {e}");
            }

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            ping,
            capture_selection,
            load_model,
            is_model_loaded,
            rephrase
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
