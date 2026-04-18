// Main (non-panel) window — hosts Models + Settings tabs.

import { useState } from "react";
import ModelManager from "./ModelManager";
import Settings from "./Settings";

type Tab = "models" | "settings";

function App() {
  const [tab, setTab] = useState<Tab>("models");
  return (
    <main
      style={{
        fontFamily: "ui-sans-serif, system-ui, sans-serif",
        padding: 0,
        minHeight: "100vh",
        backgroundColor: "#fafafa",
      }}
    >
      <header
        style={{
          padding: "18px 24px 0",
          borderBottom: "1px solid #e5e7eb",
          backgroundColor: "white",
        }}
      >
        <h1 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>Rephraser</h1>
        <p style={{ margin: "4px 0 12px", color: "#6b7280", fontSize: 13 }}>
          Press <b>Ctrl+Alt+R</b> anywhere to rephrase the selected text.
        </p>
        <nav style={{ display: "flex", gap: 4 }}>
          <TabButton label="Models" active={tab === "models"} onClick={() => setTab("models")} />
          <TabButton
            label="Settings"
            active={tab === "settings"}
            onClick={() => setTab("settings")}
          />
        </nav>
      </header>
      {tab === "models" ? <ModelManager /> : <Settings />}
    </main>
  );
}

function TabButton({
  label,
  active,
  onClick,
}: {
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      style={{
        padding: "8px 14px",
        fontSize: 13,
        fontWeight: 500,
        border: "none",
        borderRadius: "6px 6px 0 0",
        borderBottom: active ? "2px solid #2563eb" : "2px solid transparent",
        backgroundColor: "transparent",
        color: active ? "#2563eb" : "#4b5563",
        cursor: "pointer",
        marginBottom: -1,
      }}
    >
      {label}
    </button>
  );
}

export default App;
