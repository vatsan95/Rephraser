# 60-second demo video script

**Purpose:** attach to Twitter thread, pin on GitHub repo README, embed on landing page. Also the screenshot source for Product Hunt gallery + Reddit posts.

**Format:**
- 1080p, 30fps
- 55–65 seconds
- No voice-over needed (silent-friendly for Twitter autoplay)
- On-screen text captions instead
- Native UI only — no talking head, no transitions, no music

**Recording tools:**
- Mac: QuickTime screen recording → trim in iMovie → export H.264
- Windows: ShareX → export MP4
- GIF version: ffmpeg `-filter_complex "fps=15,scale=800:-1,palettegen"` etc. Keep under 5 MB for Twitter.

---

## Frame-by-frame

### 0:00 — 0:03 — The hook

**Scene:** Slack app, user is typing a snippy message into a channel:
> "Hey are you going to get the spec to me today or not?? I've been waiting since yesterday."

**Caption (top):** When you're about to send something you shouldn't…

### 0:03 — 0:05 — Selection

**Scene:** User drags to select the full message.

**Caption:** Select the text.

### 0:05 — 0:08 — The hotkey (hero moment)

**Scene:** User presses `⌥⇧R` (Mac) — on-screen key overlay shows the combo pressed.

**Caption:** Press ⌥⇧R.

### 0:08 — 0:18 — Panel appears

**Scene:** Floating panel slides in from the cursor. Shows:
- Mode dropdown (pre-selected: "Professional")
- Streaming tokens appearing: "Could you let me know the timeline for the spec? I'd like to sync on next steps."
- Diff view highlights changed words

**Caption:** Rewrite streams in. No internet needed.

### 0:18 — 0:22 — Accept

**Scene:** User presses Enter. Panel fades. Slack message field now contains the rewritten text.

**Caption:** Enter pastes it. Escape cancels.

### 0:22 — 0:28 — Context awareness

**Scene:** User cmd-tabs to Outlook. Selects a line, hits the hotkey. Panel opens — mode dropdown has auto-switched to "Concise".

**Caption:** Context-aware: soft in Slack, sharp in Outlook.

### 0:28 — 0:36 — Cross-platform

**Scene:** Quick cut to Windows laptop (or VM) doing the same thing. Notepad + `Ctrl+Alt+R`. Same panel, same flow.

**Caption:** Mac. And Windows.

### 0:36 — 0:44 — The privacy moment

**Scene:** User turns off Wi-Fi (Mac menu bar Wi-Fi icon → slash). Tries rephrase again. It works identically.

**Caption:** Works offline. Your text never leaves your laptop.

### 0:44 — 0:52 — The catalog

**Scene:** Settings → Models. Shows the 6-model catalog: Qwen 2.5 0.5B, Gemma 3 1B, Phi-4 Mini, Llama 3.2 3B, Qwen 3 4B, Gemma 3 4B. Sizes visible.

**Caption:** Pick your model. Gemma, Qwen, Phi-4, Llama.

### 0:52 — 0:58 — The CTA

**Scene:** Landing page URL fades in: `vatsan95.github.io/Rephraser/`. Small print: "Free. MIT. No account. No cloud."

**Caption:** Free forever. MIT. Grab it.

### 0:58 — 1:00 — End card

**Scene:** Rephraser logo + "github.com/vatsan95/Rephraser"

---

## The 15-second short version (for Twitter GIF)

Cut everything but 0:03 → 0:18. Add one caption at the end: "Free, offline, Mac + Windows → vatsan95.github.io/Rephraser"

---

## What NOT to do

- No voiceover with "Hi, my name is…"
- No cheesy music
- No fake cursor trail animations
- No "AMAZING PRODUCT 🚀🔥" on-screen text
- Don't show the email gate — people hate email gates even in demos
- Don't show the SmartScreen warning — for this audience it's a confidence-killer; save it for the install guide
- Don't include a face — the product is the star, not you
