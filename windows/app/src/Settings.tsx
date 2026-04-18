// Settings panel — reads/writes the Rust-side settings.json via
// `get_settings` + `update_settings` commands.

import { useCallback, useEffect, useState } from "react";
import { invoke } from "@tauri-apps/api/core";

interface Settings {
  hotkey: string;
  selectedModelID: string | null;
  analyticsEnabled: boolean;
  launchAtLogin: boolean;
  anonymousId: string | null;
  schemaVersion: number;
}

export default function Settings() {
  const [settings, setSettings] = useState<Settings | null>(null);
  const [status, setStatus] = useState<string | null>(null);

  const load = useCallback(async () => {
    setSettings(await invoke<Settings>("get_settings"));
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const patch = useCallback(
    async (p: Partial<Settings>) => {
      if (!settings) return;
      const next = { ...settings, ...p };
      setSettings(next);
      setStatus("Saving…");
      try {
        await invoke("update_settings", { settings: next });
        setStatus("Saved.");
        setTimeout(() => setStatus(null), 1200);
      } catch (e: any) {
        setStatus(`Error: ${e}`);
      }
    },
    [settings]
  );

  if (!settings) return <div style={{ padding: 16 }}>Loading settings…</div>;

  return (
    <div style={{ padding: 16, maxWidth: 560 }}>
      <h2 style={{ margin: 0, fontSize: 18 }}>Settings</h2>
      {status && (
        <div style={{ fontSize: 12, color: "#6b7280", marginTop: 4 }}>
          {status}
        </div>
      )}

      <section style={sectionStyle}>
        <label style={labelStyle}>Global hotkey</label>
        <input
          type="text"
          value={settings.hotkey}
          onChange={(e) => patch({ hotkey: e.target.value })}
          style={inputStyle}
        />
        <p style={helpStyle}>
          Customising hotkey takes effect after restart (v0.2 will hot-reload).
        </p>
      </section>

      <section style={sectionStyle}>
        <label style={labelStyle}>
          <input
            type="checkbox"
            checked={settings.launchAtLogin}
            onChange={(e) => patch({ launchAtLogin: e.target.checked })}
            style={{ marginRight: 8 }}
          />
          Launch Rephraser at login
        </label>
      </section>

      <section style={sectionStyle}>
        <label style={labelStyle}>
          <input
            type="checkbox"
            checked={settings.analyticsEnabled}
            onChange={(e) => patch({ analyticsEnabled: e.target.checked })}
            style={{ marginRight: 8 }}
          />
          Share anonymous usage analytics
        </label>
        <p style={helpStyle}>
          Event names and OS only. No text content, no file paths. Powered by
          TelemetryDeck. Opt out any time — the toggle is immediate.
        </p>
      </section>

      <section style={sectionStyle}>
        <h3 style={{ fontSize: 13, color: "#6b7280", margin: "0 0 8px" }}>
          Privacy
        </h3>
        <p style={helpStyle}>
          All rephrasing runs locally on your machine. The only network calls
          Rephraser makes are model downloads from HuggingFace (on your
          request) and — when enabled — anonymous telemetry.
        </p>
      </section>
    </div>
  );
}

const sectionStyle: React.CSSProperties = {
  marginTop: 16,
  paddingTop: 16,
  borderTop: "1px solid #e5e7eb",
};

const labelStyle: React.CSSProperties = {
  display: "block",
  fontSize: 13,
  fontWeight: 500,
  marginBottom: 6,
};

const helpStyle: React.CSSProperties = {
  fontSize: 12,
  color: "#6b7280",
  margin: "6px 0 0",
  lineHeight: 1.5,
};

const inputStyle: React.CSSProperties = {
  width: "100%",
  padding: "6px 10px",
  fontSize: 13,
  border: "1px solid #d1d5db",
  borderRadius: 6,
};
