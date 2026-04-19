# r/macapps

**Subreddit:** https://www.reddit.com/r/macapps/
**Tone:** Mac-specific, show menu bar love. Show icon + screenshot.
**Flair:** "App"

---

## Title

> Rephraser 1.0 — free, open-source menu bar AI rewriter. Uses Apple MLX, runs on your M-series chip, no cloud.

## Body

Just shipped 1.0. Sharing here because Mac is my primary platform and
I built this for my own menu bar before anything else.

**What it is:** menu bar app, `⌥⇧R` from anywhere, rephrases selected
text in any app. Native Swift + SwiftUI + Apple MLX. Auto-detects
Apple Silicon and uses Metal for inference.

**Why native MLX over llama.cpp or Ollama**
- 2–3× faster on M-series than llama.cpp for the same model
- No daemon, no separate process, no extra RAM baseline
- Models load in under 2 seconds (Gemma 3 1B on M2 Air)
- Ships as a regular `.app`, single binary, drag-to-Applications

**What's in the box**
- 9 rephrase modes + custom modes (JSON-defined system prompts you can edit)
- Model picker: Gemma 3 1B / 4B, Qwen 2.5 / Qwen 3, Phi-4 Mini, Llama 3.2 3B
- Context-aware mode: softens in Slack, tightens in Mail, concise in Xcode
- Preserves your clipboard across rephrases
- Sparkle auto-updates
- MIT licensed, no account, no telemetry of text

**System requirements**
- macOS 14 (Sonoma) or later
- Apple Silicon only (MLX is M-series exclusive). Intel Macs not supported.
- ~2 GB free RAM during rephrase, ~150 MB idle

**Menu bar details (for the menu-bar-app nerds)**
- SwiftUI MenuBarExtra
- Custom template icon that follows system tint (dark mode happy)
- Floating panel uses a borderless NSPanel pinned to the active screen,
  remembers last-used mode, animates in/out with Core Animation
- Accessibility permission requested once at first launch (needed to
  synthesize ⌘C / ⌘V for any app)

**Download (DMG)**
https://vatsan95.github.io/Rephraser/

**Source**
https://github.com/vatsan95/Rephraser

Feedback very welcome, especially from longtime menu bar app users.
What's your favourite menu bar app and what makes its UX feel right?

## First comment

> One question for the sub: icon design. Currently using a custom glyph (see screenshot). I've gone back and forth on whether to do a template icon that inherits menu bar colour, or a full-colour icon that stands out. Currently template. Worth switching to colour? What do you prefer on other menu bar apps?
