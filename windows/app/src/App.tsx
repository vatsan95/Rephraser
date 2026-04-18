// Main (non-panel) window. Hosts the model manager in Phase 5 and will
// grow Settings + onboarding in Phase 6. The tray app stays invisible
// until the user clicks "About" or manually opens this window.

import ModelManager from "./ModelManager";

function App() {
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
          padding: "18px 24px 12px",
          borderBottom: "1px solid #e5e7eb",
          backgroundColor: "white",
        }}
      >
        <h1 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>Rephraser</h1>
        <p style={{ margin: "4px 0 0", color: "#6b7280", fontSize: 13 }}>
          Press <b>Ctrl+Alt+R</b> anywhere to rephrase the selected text.
        </p>
      </header>
      <ModelManager />
    </main>
  );
}

export default App;
