// Phase 1 skeleton — the tray-only app currently has no visible window.
// When we open the settings/about panel in Phase 4, this component will host it.
function App() {
  return (
    <main style={{ fontFamily: "system-ui, sans-serif", padding: 24 }}>
      <h1>Rephraser</h1>
      <p>Tray app is running. Press your hotkey to rephrase text.</p>
    </main>
  );
}

export default App;
