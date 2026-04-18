// Frameless, always-on-top panel that opens on hotkey.
// Flow (mirrors Mac `RephrasePanel.swift`):
//   1. Rust creates the panel window and emits `panel://open` with
//      { text, previous_clipboard, suggested_mode }
//   2. Panel invokes `rephrase(text, mode)` which streams `rephrase://token`
//   3. Enter → `panel_accept(final_text, previous_clipboard)` → paste + close
//   4. Escape → `panel_dismiss(previous_clipboard)` → restore + close

import { useCallback, useEffect, useRef, useState } from "react";
import { invoke } from "@tauri-apps/api/core";
import { listen, type UnlistenFn } from "@tauri-apps/api/event";
import { getCurrentWindow } from "@tauri-apps/api/window";
import DiffView from "./DiffView";

type Mode = {
  id: string;
  displayName: string;
};

const MODES: Mode[] = [
  { id: "professional", displayName: "Professional" },
  { id: "casual", displayName: "Casual" },
  { id: "concise", displayName: "Concise" },
  { id: "elaborate", displayName: "Elaborate" },
  { id: "fixGrammar", displayName: "Fix Grammar" },
  { id: "confident", displayName: "Confident" },
  { id: "empathetic", displayName: "Empathetic" },
  { id: "summarize", displayName: "Summarize" },
  { id: "keyPoints", displayName: "Key Points" },
];

interface OpenPayload {
  text: string;
  previous_clipboard: string | null;
  suggested_mode: string;
}

interface TokenPayload {
  text: string;
  index: number;
}

interface DonePayload {
  total_tokens: number;
  duration_ms: number;
  tok_per_sec: number;
  error: string | null;
}

export default function RephrasePanel() {
  const [source, setSource] = useState("");
  const [output, setOutput] = useState("");
  const [mode, setMode] = useState("professional");
  const [streaming, setStreaming] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const prevClipboardRef = useRef<string | null>(null);
  const outputRef = useRef("");

  const startRephrase = useCallback(
    async (text: string, modeId: string) => {
      setOutput("");
      outputRef.current = "";
      setError(null);
      setStreaming(true);
      try {
        await invoke("rephrase", { text, mode: modeId });
      } catch (e: any) {
        setError(String(e));
        setStreaming(false);
      }
    },
    []
  );

  // Subscribe to open / token / done events.
  useEffect(() => {
    const unlisteners: UnlistenFn[] = [];

    (async () => {
      unlisteners.push(
        await listen<OpenPayload>("panel://open", (evt) => {
          const { text, previous_clipboard, suggested_mode } = evt.payload;
          prevClipboardRef.current = previous_clipboard;
          setSource(text);
          setMode(suggested_mode || "professional");
          void startRephrase(text, suggested_mode || "professional");
        })
      );
      unlisteners.push(
        await listen<TokenPayload>("rephrase://token", (evt) => {
          outputRef.current += evt.payload.text;
          setOutput(outputRef.current);
        })
      );
      unlisteners.push(
        await listen<DonePayload>("rephrase://done", (evt) => {
          setStreaming(false);
          if (evt.payload.error) setError(evt.payload.error);
        })
      );
    })();

    return () => {
      for (const u of unlisteners) u();
    };
  }, [startRephrase]);

  const handleAccept = useCallback(async () => {
    if (streaming || !output.trim()) return;
    await invoke("panel_accept", {
      finalText: output.trim(),
      previousClipboard: prevClipboardRef.current,
    });
    await getCurrentWindow().close();
  }, [output, streaming]);

  const handleDismiss = useCallback(async () => {
    await invoke("panel_dismiss", {
      previousClipboard: prevClipboardRef.current,
    });
    await getCurrentWindow().close();
  }, []);

  const handleModeChange = useCallback(
    (next: string) => {
      setMode(next);
      if (source) void startRephrase(source, next);
    },
    [source, startRephrase]
  );

  // Keyboard shortcuts: Enter=accept, Escape=dismiss.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        void handleAccept();
      } else if (e.key === "Escape") {
        e.preventDefault();
        void handleDismiss();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [handleAccept, handleDismiss]);

  return (
    <div
      style={{
        fontFamily: "ui-sans-serif, system-ui, sans-serif",
        backgroundColor: "rgba(20, 20, 24, 0.92)",
        color: "#f3f4f6",
        borderRadius: 12,
        padding: 16,
        boxShadow: "0 20px 40px rgba(0,0,0,0.35)",
        border: "1px solid rgba(255,255,255,0.06)",
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        gap: 12,
        overflow: "hidden",
      }}
    >
      <header
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <select
          value={mode}
          onChange={(e) => handleModeChange(e.target.value)}
          disabled={streaming}
          style={{
            backgroundColor: "rgba(255,255,255,0.06)",
            color: "#f3f4f6",
            border: "1px solid rgba(255,255,255,0.1)",
            borderRadius: 6,
            padding: "4px 8px",
            fontSize: 13,
          }}
        >
          {MODES.map((m) => (
            <option key={m.id} value={m.id}>
              {m.displayName}
            </option>
          ))}
        </select>
        <div style={{ fontSize: 11, opacity: 0.6 }}>
          Enter · accept &nbsp;·&nbsp; Esc · dismiss
        </div>
      </header>

      <div
        style={{
          flex: 1,
          overflow: "auto",
          backgroundColor: "rgba(255,255,255,0.03)",
          borderRadius: 8,
          padding: 12,
        }}
      >
        <DiffView before={source} after={output} streaming={streaming} />
        {error && (
          <div style={{ marginTop: 8, color: "#f87171", fontSize: 12 }}>
            {error}
          </div>
        )}
      </div>
    </div>
  );
}
