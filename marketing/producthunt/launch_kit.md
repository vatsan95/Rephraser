# Product Hunt launch kit (Windows relaunch)

**URL:** https://www.producthunt.com/posts/new
**Best launch day:** Tuesday–Thursday, 12:01am PT. First 4 hours drive rank.
**Launch day:** share the PH link on Twitter, LinkedIn, Reddit r/ProductHuntDaily at the same 12:01am PT moment.
**Assets required:** logo (240×240 PNG transparent), 3–6 gallery images (1270×760), optional 10–60 sec video.

---

## Product name

> Rephraser for Windows

## Tagline (60 char max)

> Free AI text rewriter for Windows. Offline. No cloud. MIT.

Alt taglines:
- One shortcut. Any app. AI rephrasing that runs on your PC.
- Copilot alternative — no account, no subscription, no cloud.
- Free offline AI text rewriter for Windows 10 and 11.

## Topic / categories

Primary: **Productivity**
Secondary: **Artificial Intelligence**, **Writing Tools**, **Open Source**

## Description (260 chars, supports markdown-ish)

> Rephraser is a tiny tray app that rewrites selected text in any Windows app with `Ctrl+Alt+R`. Runs 100% offline via llama.cpp. Free forever, MIT licensed, no account. Works in Word, Outlook, Chrome, Slack, VS Code — anywhere you can copy text.

## Launch comment (first comment on your own PH launch — critical for conversion)

> Hey PH — Srivatsan here 👋
>
> Rephraser has been on Mac since late 2025 and I just shipped the Windows port. Same app, same philosophy: one shortcut, any app, fully on-device.
>
> **Why I built the Windows version**
> Because Windows already has Microsoft Copilot, Grammarly, Wordtune — and every one of them sends your text to a cloud server. I wanted something that:
> - Works with Wi-Fi off
> - Costs $0 forever (no "premium" tier coming)
> - Is small enough to install in 10 seconds (15 MB)
> - Doesn't need a Microsoft account / email sign-up / anything
>
> **What's under the hood**
> - Rust + Tauri 2 (not Electron)
> - llama.cpp via llama-cpp-2 bindings for inference
> - Pick your model at first launch: Gemma 3 1B (recommended, 800 MB) or Qwen 2.5 0.5B (fastest, 400 MB) if you're on a weak laptop
> - Works in Word, Outlook, Chrome, Edge, Slack, Discord, Teams, VS Code, Notepad
> - MSI available for enterprise `/quiet` silent install
>
> **Fair warnings (it's v0.1 beta)**
> - EXE isn't code-signed yet — SmartScreen shows "Unknown publisher" and you have to click "More info → Run anyway" once. Certum OSS cert arrives after ~100 installs.
> - x64 only in v0.1; ARM64 (Snapdragon X / Copilot+ PCs) in v0.2
>
> **Free forever** — source is MIT at github.com/vatsan95/Rephraser. Donations (PayPal) are always welcome but never required.
>
> Would love your feedback, especially on what feature you'd want next. Drop a comment — I'll answer every one today.

## Gallery caption ideas

1. "One keystroke. Any app. AI rephrasing in 1.4 seconds." (show hotkey + before/after)
2. "9 rephrase modes. Unlimited custom ones." (show mode picker)
3. "Choose your model — Gemma, Qwen, Phi-4, or Llama." (show model catalog)
4. "Works entirely offline. Airplane mode friendly." (show Wi-Fi off icon + rephrase happening)
5. "15 MB installer. ~150 MB RAM idle." (compare with Grammarly desktop)
6. "MIT licensed. Zero telemetry of your text." (show GitHub repo with MIT badge)

## Maker comment cheat sheet

When someone says:
- **"Looks like another AI wrapper"** → "Fair — most are. What makes this one not: it's the model picker + on-device execution. Your text literally cannot leave your laptop because no code in the rephrase path makes a network call. Source: github.com/vatsan95/Rephraser, grep for `http` in the inference module."
- **"Why not Chrome extension?"** → "Because it wouldn't work in Word, Outlook, Slack desktop, Discord, VS Code, Cursor. The point is system-wide."
- **"Is there a Mac version?"** → "Yes, same name, same philosophy, Swift+MLX instead of Rust+llama.cpp. PH page from earlier launch: [link if available, else 'also in the same repo']."
- **"Roadmap?"** → "Short term: code signing, ARM64, one-shot mode (rephrase without panel for trust-the-model mode). Long term: Linux, richer format preservation (RTF/HTML round-trip), on-device fine-tunes for people who want their own voice."

## Launch-day promo posts

**Twitter at 12:01am PT:**
> Rephraser for Windows is live on Product Hunt 🚀
> Free, offline AI text rewriter. No cloud, no account, MIT.
> [PH link]

**LinkedIn at 12:01am PT:**
> Shipped: Rephraser for Windows. Free + offline AI writing tool, no cloud, MIT licensed. Months of work — would mean a lot if you gave it a look on Product Hunt: [PH link]

**Reddit r/ProductHuntDaily:**
> Title: "Rephraser for Windows — free offline AI rewriter, launching today on PH"
> (Low-effort post is fine here; the sub exists for exactly this.)
