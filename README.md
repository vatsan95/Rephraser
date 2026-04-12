# Rephraser

**Rephrase text in any app with a single keyboard shortcut. Powered by on-device AI.**

Rephraser is a lightweight macOS menu bar app that lets you select text anywhere — Slack, Gmail, Notion, VS Code, Discord, your browser — press `⌥⇧R`, and instantly get a polished version. AI runs entirely on your Mac using [MLX](https://github.com/ml-explore/mlx-swift). No API keys, no cloud, no cost.

## How It Works

1. **Select text** in any application
2. **Press `⌥⇧R`** (Option + Shift + R)
3. **Review** the rephrased text in the floating panel
4. **Accept** (Enter) to replace, or **Dismiss** (Escape) to cancel

## Features

- **On-device AI** — Models run locally via Apple MLX. Your text never leaves your Mac.
- **System-wide** — Works in any app where you can select text.
- **Multiple modes** — Professional, Casual, Concise, Elaborate, Fix Grammar, plus custom modes.
- **Streaming** — See the rephrased text appear token-by-token in real time.
- **Non-destructive** — Your clipboard is preserved. Original text is untouched until you accept.
- **Lightweight** — Lives in the menu bar. No dock icon, minimal memory when idle.

## Supported Models

Download any of these directly from within the app:

| Model | Size | Notes |
|-------|------|-------|
| **Gemma 4 E4B** (recommended) | ~3 GB | Google's latest Gemma 4 — best quality for rephrasing |
| Gemma 3 4B | ~2.5 GB | Google's Gemma 3 — proven, fast, lightweight |
| Qwen 3 4B | ~2.5 GB | Strong multilingual support |
| Phi-4 Mini | ~2.3 GB | Microsoft — compact and efficient |
| Llama 3.2 3B | ~1.8 GB | Meta — smallest option, fastest speed |

## Requirements

- **macOS 14** (Sonoma) or later
- **Apple Silicon** (M1, M2, M3, M4)
- ~3 GB disk space for the AI model
- ~3 GB RAM during inference (fits comfortably on 8 GB Macs)

## Building from Source

```bash
# Clone
git clone https://github.com/vatsan95/Rephraser.git
cd Rephraser

# Build with Swift Package Manager
swift build

# Or open in Xcode
# Generate the Xcode project first (if using XcodeGen):
# xcodegen generate
# Then open Rephraser.xcodeproj
```

**Note:** The first build will download MLX Swift dependencies (~5 min). Subsequent builds are fast.

## Project Structure

```
Rephraser/
├── RephraserApp.swift           # App entry point, AppDelegate
├── AppState.swift               # Observable settings/config
├── Coordinator/
│   └── RephraseCoordinator.swift # State machine orchestrating the flow
├── Services/
│   ├── ModelManager.swift       # Model download, load, lifecycle
│   ├── RephraseService.swift    # MLX inference, streaming
│   ├── HotkeyService.swift      # Global keyboard shortcut
│   ├── TextCaptureService.swift  # Clipboard capture/paste
│   ├── ClipboardSnapshot.swift   # Clipboard save/restore
│   └── SourceAppTracker.swift    # Source app tracking for refocus
├── Models/
│   ├── LocalModel.swift         # Model catalog
│   ├── RephraseMode.swift       # Rephrase modes + system prompts
│   ├── RephraseResult.swift     # Result data structure
│   └── AppError.swift           # Error types
├── Views/
│   ├── MenuBarView.swift        # Menu bar popover
│   ├── RephrasePanel.swift      # Floating result panel (NSPanel)
│   ├── RephrasePanelContent.swift
│   ├── SettingsView.swift       # Settings (General, Model, Modes)
│   ├── OnboardingView.swift     # First-launch setup
│   └── Components/
│       └── StreamingTextView.swift
└── Utilities/
    ├── AccessibilityHelper.swift
    ├── CGEventHelpers.swift
    └── RetryHelper.swift
```

## Tech Stack

- **Swift + SwiftUI** — Native macOS, menu bar app
- **MLX Swift** — Apple's ML framework for on-device inference
- **HotKey** — Global keyboard shortcut registration
- **Sparkle** — Auto-update framework

## Privacy

Rephraser is designed to be private by default:

- AI inference happens **entirely on your device**
- **No text is sent to any server** — ever
- No accounts, no telemetry, no analytics
- Your clipboard is restored after every operation

## License

MIT — see [LICENSE](LICENSE).
