//! Rephraser for Windows — Phase 1 skeleton + Phase 2 hotkey/clipboard
//! + Phase 3 inference + Phase 4 floating panel.

mod clipboard;
mod context;
mod hotkey;
mod inference;
mod models;
mod panel;

use tauri::{
    menu::{Menu, MenuItem},
    tray::TrayIconBuilder,
    Listener, Manager,
};

#[tauri::command]
fn ping() -> &'static str {
    "pong"
}

/// Command invoked from the hotkey event bridge (or frontend for testing).
/// Snapshots clipboard, synthesizes Ctrl+C, returns the captured selection.
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

/// Phase 5: return the compiled-in model catalog.
#[tauri::command]
fn list_catalog() -> &'static models::Catalog {
    models::catalog()
}

/// Phase 5: list installed models in %LOCALAPPDATA%\\Rephraser\\models\\.
#[tauri::command]
async fn list_installed_models(app: tauri::AppHandle) -> Result<Vec<models::InstalledModel>, String> {
    models::list_installed(&app).map_err(|e| e.to_string())
}

/// Phase 5: download a GGUF by catalog id. Emits `download://progress`.
#[tauri::command]
async fn download_model(app: tauri::AppHandle, id: String) -> Result<String, String> {
    let path = models::download(app, id).await.map_err(|e| e.to_string())?;
    Ok(path.to_string_lossy().into_owned())
}

/// Phase 5: delete an installed model.
#[tauri::command]
async fn delete_model(app: tauri::AppHandle, id: String) -> Result<(), String> {
    models::delete(&app, &id).map_err(|e| e.to_string())
}

/// Phase 4: user hit Enter — paste the rephrased text at caret, then
/// restore the original clipboard so we don't hijack their buffer.
#[tauri::command]
async fn panel_accept(
    app: tauri::AppHandle,
    final_text: String,
    previous_clipboard: Option<String>,
) -> Result<(), String> {
    clipboard::restore(&final_text).map_err(|e| e.to_string())?;
    clipboard::synth_paste().map_err(|e| e.to_string())?;

    // Give the target app a moment to consume Ctrl+V before we overwrite.
    let prev = previous_clipboard.clone();
    tauri::async_runtime::spawn(async move {
        tokio::time::sleep(std::time::Duration::from_millis(150)).await;
        if let Some(p) = prev {
            let _ = clipboard::restore(&p);
        }
    });

    panel::close_panel(&app);
    Ok(())
}

/// Phase 4: user hit Escape — just restore their clipboard and close.
#[tauri::command]
async fn panel_dismiss(
    app: tauri::AppHandle,
    previous_clipboard: Option<String>,
) -> Result<(), String> {
    if let Some(p) = previous_clipboard {
        let _ = clipboard::restore(&p);
    }
    panel::close_panel(&app);
    Ok(())
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
                        tracing::info!("About clicked (settings window lands in Phase 6)");
                    }
                    _ => {}
                })
                .build(app)?;

            // Global hotkey (Phase 2)
            let app_handle = app.handle().clone();
            if let Err(e) = hotkey::init(&app_handle) {
                tracing::warn!("Failed to init hotkey: {e}");
            }

            // Phase 4: listen for hotkey events on the main thread and
            // drive the capture → panel flow here, not in the hotkey
            // listener thread (keeps that thread as a pure event pump).
            let app_for_hotkey = app.handle().clone();
            app.listen_any("hotkey://pressed", move |_evt| {
                let app_clone = app_for_hotkey.clone();
                tauri::async_runtime::spawn(async move {
                    handle_hotkey(app_clone).await;
                });
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            ping,
            capture_selection,
            load_model,
            is_model_loaded,
            rephrase,
            panel_accept,
            panel_dismiss,
            list_catalog,
            list_installed_models,
            download_model,
            delete_model
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

/// Hotkey → capture clipboard → show panel → rephrase.
/// Runs on the tokio runtime so it doesn't block the Tauri main loop.
async fn handle_hotkey(app: tauri::AppHandle) {
    let previous = clipboard::snapshot();
    let captured = match clipboard::capture_selection(previous.as_deref()) {
        Ok(t) => t,
        Err(e) => {
            tracing::warn!("capture_selection failed: {e}");
            return;
        }
    };
    let process = context::foreground_process_name().unwrap_or_default();
    let suggested_mode = context::mode_for_process(&process).to_string();

    let payload = panel::OpenPayload {
        text: captured,
        previous_clipboard: previous,
        suggested_mode,
    };
    if let Err(e) = panel::show_panel(&app, payload) {
        tracing::warn!("show_panel failed: {e}");
    }
    // RephrasePanel invokes `rephrase(...)` itself after it renders —
    // decoupling "window up" from "inference running" keeps the UI
    // responsive even when the model takes a beat to kick off.
}
