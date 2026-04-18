import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";
import RephrasePanel from "./RephrasePanel";

// Same bundle serves both the (invisible) tray-owning main window and the
// rephrase panel. Rust picks which view by appending `?view=panel` when
// creating the panel window in `panel.rs`.
const params = new URLSearchParams(window.location.search);
const view = params.get("view");

const root = ReactDOM.createRoot(
  document.getElementById("root") as HTMLElement
);

if (view === "panel") {
  root.render(
    <React.StrictMode>
      <RephrasePanel />
    </React.StrictMode>
  );
} else {
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}
