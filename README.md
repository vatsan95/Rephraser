# Rephraser

**Rephrase text in any app with a single keyboard shortcut. Powered by on-device AI. Free on Mac and Windows.**

Rephraser is a lightweight tray / menu-bar app for **macOS** and **Windows** that lets you select text anywhere — Slack, Gmail, Notion, VS Code, Discord, Outlook, Word, your browser — press the hotkey, and instantly get a polished version. AI runs entirely on your device via [MLX](https://github.com/ml-explore/mlx-swift) on Mac and [llama.cpp](https://github.com/ggerganov/llama.cpp) on Windows. No API keys, no cloud, no cost.

| Platform | Default hotkey | Install |
|----------|----------------|---------|
| macOS 14+ (Apple Silicon) | `⌥⇧R` (Option + Shift + R) | [Download DMG](https://github.com/vatsan95/Rephraser/releases/latest) |
| Windows 10 1809+ / Windows 11 (x64) | `Ctrl + Alt + R` | [Download EXE](https://github.com/vatsan95/Rephraser/releases/latest) · [Install guide](https://vatsan95.github.io/Rephraser/windows.html) |

Full Windows development docs: [`windows/README.md`](windows/README.md).
Website: [vatsan95.github.io/Rephraser](https://vatsan95.github.io/Rephraser/).

## How It Works

1. **Select text** in any application
2. **Press your hotkey** — `⌥⇧R` on Mac, `Ctrl + Alt + R` on Windows (both remappable in Settings)
3. **Review** the rephrased text in the floating panel, with a diff against your original
4. **Accept** (Enter) to replace, or **Dismiss** (Escape) to cancel — your clipboard is preserved either way

## Features

- **On-device AI** — Apple MLX on Mac, llama.cpp on Windows. Your text never leaves your computer.
- **System-wide** — Works in any app where you can select text.
- **9 built-in modes** — Professional, Casual, Concise, Elaborate, Fix Grammar, Confident, Empathetic, Summarize, Key Points — plus unlimited custom modes with your own system prompts.
- **Context-aware** — Auto-suggests tone based on the source app (Slack → Casual, Outlook / Gmail → Professional, VS Code → Concise).
- **Diff view** — See exactly what changed between your original and the rephrased version.
- **Streaming** — Tokens appear in real time, not behind a spinner.
- **Non-destructive** — Your clipboard is snapshotted and restored after every operation. Original text is untouched until you accept.
- **Lightweight** — Menu bar on Mac, system tray on Windows. No dock icon, minimal memory when idle.
- **Escape cancels mid-stream** — Hit Esc and inference aborts before any partial result can touch your clipboard.

## Supported Models

Download any of these from within the app — no terminal needed:

| Model | Size | Notes |
|-------|------|-------|
| **Gemma 3 1B** (recommended) | ~0.8 GB | Google's Gemma 3 — fast download, great for quick rephrasing |
| Gemma 3 4B | ~2.5 GB | Google's Gemma 3 — best quality |
| Qwen 3 4B | ~2.5 GB | Alibaba — strong multilingual support |
| Phi-4 Mini | ~2.3 GB | Microsoft — compact and efficient |
| Llama 3.2 3B | ~1.8 GB | Meta — smallest, fastest |

The Mac build loads models in MLX-safetensors format; the Windows build loads the equivalent GGUF quant (Q4_K_M) from [bartowski on HuggingFace](https://huggingface.co/bartowski).

## Requirements

**macOS**
- macOS 14 (Sonoma) or later
- Apple Silicon (M1, M2, M3, M4, …)
- ~2–3 GB RAM during inference (comfortable on 8 GB Macs)
- ~0.8 GB free disk for the default model

**Windows**
- Windows 10 version 1809 (October 2018 Update) or later, or Windows 11
- x64 CPU (ARM64 planned for v0.2)
- 4 GB RAM minimum, 8 GB recommended
- ~1 GB free disk for the installer + default model
- Microsoft Edge WebView2 — bundled by the installer

## Building from Source

### macOS

```bash
git clone https://github.com/vatsan95/Rephraser.git
cd Rephraser
swift build
# Or open Rephraser.xcodeproj in Xcode after `xcodegen generate`.
```

First build pulls MLX Swift dependencies (~5 min). Subsequent builds are fast.

### Windows

```powershell
git clone https://github.com/vatsan95/Rephraser.git
cd Rephraser\windows\app
pnpm install
pnpm tauri dev
```

Prerequisites: Node 20+, pnpm 9, Rust stable (`rust-toolchain.toml` pins it), Microsoft C++ Build Tools, CMake. Full instructions in [`windows/README.md`](windows/README.md).

## Project Structure

```
Rephraser/
├── Rephraser/                      # macOS app (Swift + SwiftUI + MLX)
│   ├── RephraserApp.swift
│   ├── Coordinator/RephraseCoordinator.swift
│   ├── Services/                   # HotkeyService, RephraseService, TextCaptureService, …
│   ├── Models/                     # LocalModel, RephraseMode, RephraseResult, AppError
│   └── Views/                      # MenuBarView, RephrasePanel, SettingsView, OnboardingView
│
├── windows/                        # Windows port (Tauri 2 + Rust + llama.cpp + React)
│   ├── app/
│   │   ├── src-tauri/src/          # inference, hotkey, clipboard, context, models, settings, analytics
│   │   └── src/                    # React frontend: RephrasePanel, Settings, ModelManager, Onboarding
│   ├── poc/                        # Phase 0 de-risk CLI
│   ├── DECISIONS.md                # Architecture decision log
│   └── README.md                   # Windows dev setup
│
├── shared/
│   ├── prompts/modes.json          # System prompts (source of truth for both platforms)
│   └── models/catalog.json         # GGUF catalog for Windows (MLX catalog lives in Swift)
│
├── docs/                           # vatsan95.github.io/Rephraser (GitHub Pages)
│   ├── index.html                  # Cross-platform landing page
│   ├── windows.html                # Windows install guide + VirusTotal note
│   ├── privacy.html                # Unified privacy policy
│   └── windows/latest.json         # Tauri auto-update feed
│
└── .github/workflows/
    ├── windows-build.yml           # cargo-deny → build MSI/NSIS → VirusTotal → release on win-v*
    └── windows-poc.yml             # Phase 0 gate
```

## Tech Stack

**macOS build**
- Swift + SwiftUI — native menu-bar app
- MLX Swift — Apple's on-device ML framework
- HotKey — global keyboard shortcut registration
- Sparkle — auto-update framework

**Windows build**
- Tauri 2 + Rust — ~13 MB installer, native look
- llama.cpp (via `llama-cpp-2`) — CPU-only GGUF inference
- React 18 + Vite + TypeScript — floating panel and settings UI
- `global-hotkey` + `arboard` + `enigo` — hotkey + clipboard + synthetic paste
- Tauri updater — auto-update feed served from GitHub Pages

**Both**
- TelemetryDeck — privacy-first anonymous analytics, opt-out. Same `appID` across Mac and Windows — dashboard segments by `os` payload field. No text content is ever collected.

## Privacy

- AI inference happens **entirely on your device** on both platforms.
- **No text is sent to any server, ever** — no cloud routing, no "enhanced" modes that fall back to cloud.
- No accounts, no API keys, no subscription.
- Optional anonymous usage analytics via [TelemetryDeck](https://telemetrydeck.com) — event counts only (e.g. `rephraseStarted`, `modelDownloaded`), never text, never file paths. Opt out in Settings → Analytics.
- Your clipboard is snapshotted and restored after every operation.
- Full breakdown: [vatsan95.github.io/Rephraser/privacy.html](https://vatsan95.github.io/Rephraser/privacy.html).

## License

MIT — see [LICENSE](LICENSE). Third-party attributions in [`windows/NOTICE.md`](windows/NOTICE.md) cover llama.cpp, Tauri, and all vendored Rust crates on the Windows side.
