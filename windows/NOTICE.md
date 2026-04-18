# Rephraser for Windows — Third-Party Notices

Rephraser for Windows is MIT-licensed. It bundles and/or links against the
following third-party components. This file is an informational roll-up;
authoritative license text ships inside each dependency in `Cargo.lock` /
`node_modules` and is reproduced verbatim in the MSI installer under
`LICENSE.txt`.

## Core runtime

- **[Tauri 2](https://tauri.app)** — MIT OR Apache-2.0. App shell, WebView2
  host, bundler, auto-updater.
- **[llama.cpp](https://github.com/ggerganov/llama.cpp)** — MIT. GGUF
  inference engine, vendored through `llama-cpp-2`.
- **[llama-cpp-2](https://crates.io/crates/llama-cpp-2)** — MIT/Apache-2.0.
  Safe Rust bindings over llama.cpp.
- **[Microsoft Edge WebView2 Runtime](https://developer.microsoft.com/en-us/microsoft-edge/webview2/)**
  — Distributed separately by Microsoft under its own terms. The installer
  bootstraps it if missing.

## Rust crates (non-exhaustive)

| Crate | License | Use |
|-------|---------|-----|
| `anyhow`, `thiserror` | MIT/Apache-2.0 | Error plumbing |
| `serde`, `serde_json` | MIT/Apache-2.0 | Settings + IPC payloads |
| `tokio`, `futures-util` | MIT | Async runtime + streaming |
| `reqwest` (rustls) | MIT/Apache-2.0 | Model downloads, telemetry POST |
| `rustls`, `ring` | MPL-2.0 / MIT-AND-ISC-AND-OpenSSL | TLS |
| `arboard` | MIT/Apache-2.0 | Clipboard snapshot/restore |
| `enigo` | MIT | Synthetic Ctrl+C / Ctrl+V |
| `global-hotkey` | MIT/Apache-2.0 | System-wide hotkey |
| `windows` | MIT/Apache-2.0 | Win32 FFI (process, monitor, disk) |
| `hf-hub` | Apache-2.0 | HuggingFace GGUF fetcher |
| `sha2`, `getrandom` | MIT/Apache-2.0 | Anonymous telemetry id |
| `tracing`, `tracing-subscriber` | MIT | Structured logging |
| `once_cell` | MIT/Apache-2.0 | Lazy singletons |

Full list is produced by `cargo license --json` in CI and gated by
`cargo-deny` against the allow-list in `windows/app/src-tauri/deny.toml`.

## Frontend dependencies

- **React 18** — MIT
- **TypeScript** — Apache-2.0
- **Vite** — MIT
- **@tauri-apps/api** — MIT/Apache-2.0

## Models

GGUF weights are downloaded on demand by the user from HuggingFace. Each
model is licensed by its upstream author:

- Gemma 3 — Google's **Gemma Terms of Use** (accept at first download).
- Phi-4 Mini — MIT (Microsoft).
- Llama 3.2 — **Llama 3.2 Community License** (Meta).
- Qwen 2.5 / Qwen 3 — Apache-2.0 (Alibaba).

Rephraser does not redistribute any model weights in the installer.
