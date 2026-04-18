# Rephraser for Windows

Native Windows port of [Rephraser](../README.md). Same product; different stack.

- **Shell:** [Tauri 2](https://tauri.app) + React/TypeScript
- **Inference:** [llama.cpp](https://github.com/ggerganov/llama.cpp) via `llama-cpp-2`
- **Models:** GGUF (Qwen 2.5, Phi-4 Mini, Llama 3.2, Gemma 3, Qwen 3)

## User-facing docs

See the [Windows install guide](https://vatsan95.github.io/Rephraser/windows.html)
for the SmartScreen walkthrough, system requirements, and VirusTotal
transparency.

## Directory layout

```
windows/
  poc/                         Phase 0 PoC (standalone llama-cpp-2 CLI)
  app/
    src-tauri/                 Rust backend — inference, clipboard, hotkey,
                               models, panel, settings, analytics
    src/                       React frontend — App, ModelManager, Settings,
                               RephrasePanel, DiffView
    package.json
    vite.config.ts
  DECISIONS.md                 Architectural decision log
  NOTICE.md                    Third-party attributions
  CHANGELOG.md                 Keep-a-Changelog format
```

Shared assets (prompt modes, model catalog) live under `/shared/` at the
repo root.

## Development setup

Prerequisites:
- Rust stable (pinned via `windows/app/src-tauri/rust-toolchain.toml`)
- Node 20 + pnpm 9
- Microsoft Visual Studio 2022 Build Tools with the "Desktop development with C++" workload (for `llama-cpp-sys-2`)
- CMake 3.21+
- Microsoft Edge WebView2 runtime (ships with Windows 11; auto-installed by the installer on 10)

Once toolchains are in place:

```pwsh
cd windows\app
pnpm install
pnpm tauri dev
```

The first build takes 8–15 minutes while `llama-cpp-sys-2` compiles. Subsequent
incremental builds are under 10 seconds.

### Running with a local GGUF

To avoid the onboarding download flow, drop any GGUF file into
`%LOCALAPPDATA%\Rephraser\models\` and set `selectedModelID` in
`%LOCALAPPDATA%\Rephraser\settings.json` to match the filename stem.

## Release process

1. Bump `version` in `windows/app/src-tauri/tauri.conf.json` and
   `windows/app/package.json`.
2. Update `windows/CHANGELOG.md`.
3. Push to `main` — the `Windows Build` workflow compiles + runs cargo-deny.
4. Tag `win-v<version>` (e.g. `win-v0.1.0`). A release workflow (Phase 10) will
   upload the MSI + NSIS artifacts and refresh `docs/windows/latest.json`.

## CI

`.github/workflows/windows-build.yml` runs on every push touching
`windows/app/**`:

1. `deny` (Ubuntu) — `cargo-deny check` against `src-tauri/deny.toml`.
2. `build` (Windows) — fmt, clippy `-D warnings`, `pnpm tauri build`, bundle-size gate (<25 MB), artifact upload. VirusTotal scan runs when `VT_API_KEY` is set.

## Parity with Mac

Product surface intentionally matches the Mac version: 9 rephrase modes
(source of truth in `shared/prompts/modes.json`), context-aware tone mapping
(see `context.rs`), TelemetryDeck analytics under the **same app ID** so both
platforms roll up into one dashboard (segmented by `os` payload).

Known divergence for v0.1:
- No rich-text / HTML clipboard round-trip (Mac preserves RTF; Windows
  rephrases and pastes plain text in v0.1).
- UI is English-only (i18n hooks land later).
- Updater signing + Certum code-signing cert deferred — see
  [`DECISIONS.md`](DECISIONS.md).
