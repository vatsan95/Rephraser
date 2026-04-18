//! TelemetryDeck analytics — fire-and-forget, gated on settings.
//!
//! Reuses the Mac app's `appID` so Mac + Windows unify in one dashboard,
//! segmented by the `os` payload field. No PII: no text, no file paths.
//!
//! All calls are no-ops if `analytics_enabled = false` or if the network
//! write fails — we never block user flows on telemetry.

use once_cell::sync::Lazy;
use serde::Serialize;
use tauri::AppHandle;

use crate::settings;

// Shared with macOS — see Mac `Analytics.swift`.
const APP_ID: &str = "9D29D1D7-0795-4801-9AA6-B8B42CF9D514";
const ENDPOINT: &str = "https://nom.telemetrydeck.com/v2/";

static SESSION_ID: Lazy<String> = Lazy::new(|| {
    let mut b = [0u8; 16];
    if getrandom::getrandom(&mut b).is_err() {
        return "unknown-session".into();
    }
    b.iter().map(|x| format!("{x:02x}")).collect()
});

#[derive(Debug, Clone, Serialize)]
struct Payload {
    #[serde(rename = "appID")]
    app_id: &'static str,
    #[serde(rename = "clientUser")]
    client_user: String,
    #[serde(rename = "sessionID")]
    session_id: String,
    #[serde(rename = "type")]
    event_type: String,
    payload: serde_json::Value,
}

/// Fire an event. Payload keys (mode, modelID, etc.) are arbitrary JSON.
/// `os` is auto-injected.
pub fn emit(app: &AppHandle, event: &str, mut payload: serde_json::Value) {
    let settings = settings::load(app);
    if !settings.analytics_enabled {
        return;
    }
    let Some(client_user) = settings::ensure_anonymous_client_hash(app) else {
        return;
    };
    if payload.get("os").is_none() {
        if let Some(obj) = payload.as_object_mut() {
            obj.insert("os".to_string(), serde_json::json!("windows"));
        } else {
            payload = serde_json::json!({ "os": "windows" });
        }
    }
    let body = Payload {
        app_id: APP_ID,
        client_user,
        session_id: SESSION_ID.clone(),
        event_type: event.to_string(),
        payload,
    };

    // Fire-and-forget on the tauri async runtime.
    tauri::async_runtime::spawn(async move {
        let client = match reqwest::Client::builder()
            .user_agent("Rephraser-Windows/0.1")
            .build()
        {
            Ok(c) => c,
            Err(e) => {
                tracing::debug!("analytics client build failed: {e}");
                return;
            }
        };
        if let Err(e) = client
            .post(ENDPOINT)
            .json(&[&body]) // TelemetryDeck v2 expects an array
            .send()
            .await
        {
            tracing::debug!("analytics send failed: {e}");
        }
    });
}
