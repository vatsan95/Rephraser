# r/opensource

**Subreddit:** https://www.reddit.com/r/opensource/
**Angle:** MIT license, no telemetry, no premium tier. "Freemium is a lie" framing.
**Flair:** "Promotional"

---

## Title

> Rephraser: MIT-licensed AI text rewriter for Mac and Windows. Runs offline, no premium tier, no telemetry of your text.

## Body

Most "free" writing tools are gated trials — Grammarly Free is Grammarly
Broken, Wordtune Free is 3 rewrites a day. I wanted something where
"free" actually meant free, so I built it.

**Rephraser** — a menu bar / tray app that rewrites selected text in any
app with one shortcut. MIT licensed, fully on-device AI, no account,
no telemetry of your text content, no paid tier, no "premium features".

- Mac: Swift + Apple MLX → https://github.com/vatsan95/Rephraser
- Windows: Rust + Tauri + llama.cpp
- Models: Gemma 3, Qwen, Phi-4, Llama 3.2 — you pick at first launch

**What's actually MIT**
The entire app, both platforms. Every dependency is license-audited in
CI via `cargo-deny` (license allowlist: MIT, Apache-2.0, BSD, ISC, MPL-2,
Unicode-3.0, Zlib, BSL-1.0, CC0, CDLA-Permissive-2.0). Zero GPL infection
in the tree. If a transitive dep changes license, CI fails.

**What about analytics?**
Opt-out. Off by default on Windows, on-by-default on Mac (I'll align
both to off-by-default in v1.1). When on, the only thing reported is:
- appLaunched
- rephraseStarted
- rephraseAccepted / Rejected
- modelDownloaded
- modeChanged
- OS identifier

**Never** your text, clipboard, file paths, IP, or anything identifying.
Provider is TelemetryDeck (EU-hosted, GDPR, salted-hash client ID). One
toggle in Settings disables everything.

**What about crash reports?**
Same story — opt-in, Sentry, text content scrubbed before send, file
paths redacted. `analyticsEnabled = false` kills both analytics and
crash reports.

**Why MIT not AGPL?**
Debated it. Ended up picking MIT because the threat model is "someone
forks this and sells it behind a paywall" — if they do, good, they're
still giving people offline AI rephrasing. AGPL wouldn't change that
calculus meaningfully for a client-side tool.

**Builders wanted**
The Linux port doesn't exist because I can't test it. If you use Linux
and are curious, `windows/app/src-tauri/src/` is pretty portable and
`global-hotkey` crate works on X11 + Wayland. PRs very welcome.

## First comment

> Proof of the no-telemetry-of-text claim: the analytics code is at `windows/app/src-tauri/src/analytics.rs` and the Mac equivalent at `Rephraser/Services/Analytics.swift`. Grep for `text` or `clipboard` in those files — you won't find them. The payloads are defined as typed structs with no free-form fields.
