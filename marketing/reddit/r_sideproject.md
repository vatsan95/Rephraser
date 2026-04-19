# r/SideProject

**Subreddit:** https://www.reddit.com/r/SideProject/
**Rules:** Lenient. Mods want honest stories + proof of effort. Links OK.
**Best time to post:** Monday–Wednesday, 9–11am EST.
**Flair:** "Feedback Request" or "Show & Tell"

---

## Title (pick one, A/B tested style)

> I got tired of paying Grammarly $12/mo, so I built a free open-source AI rewriter that runs 100% on your laptop

Alt titles:
- Built a Grammarly alternative that runs offline on Mac + Windows. Free forever, MIT licensed.
- Spent 6 months building an AI text rewriter that doesn't send your words to the cloud

## Body

I'm a solo dev and kept running into the same wall: every AI writing tool
either wants a subscription (Grammarly, Wordtune), routes my text through
someone else's servers (Copilot, ChatGPT), or both.

So I built **Rephraser** — a menu-bar / tray app that rephrases any selected
text in any app with one keyboard shortcut. Fully on-device via Apple MLX
on Mac and llama.cpp on Windows. No cloud, no API keys, no account, no
upsell. MIT license.

**What it does**
- Select text anywhere (Word, Slack, Chrome, VS Code, Outlook…)
- Press `⌥⇧R` on Mac or `Ctrl+Alt+R` on Windows
- A small panel floats above your work, streams the rewrite, Enter pastes

**9 tones** (casual / professional / concise / friendly / creative / confident
/ shorter / longer / fix typos) + custom modes. Context-aware: it softens
tone in Slack and tightens it in Outlook without you picking a mode.

**What's weird about it**
- The whole app is ~15 MB. The model is a separate ~0.8 GB download you
  pick at first launch (Gemma 3 1B by default; Qwen, Phi-4 Mini, Llama 3.2
  also work).
- Zero telemetry of your text. Opt-out analytics only reports "rephrase
  happened" + model ID + OS, no content.
- Windows build is a pure Rust/Tauri app; Mac is Swift/SwiftUI. Two
  codebases on purpose — native feel matters more than shared code.

**Free / paid**
It's free. No paid tier planned. Costs me $0/mo to run (GitHub Pages +
your laptop does the inference). If you like it enough to buy me a coffee,
there's a PayPal link, otherwise just star the repo.

**Downloads**
- Site: https://vatsan95.github.io/Rephraser/
- GitHub: https://github.com/vatsan95/Rephraser

Would love brutal feedback — especially on the Windows beta. What would
make you actually switch from Grammarly / Copilot?

## First comment (reply to yourself, pin it)

> A few things I know are rough that I'm working on:
> 1. Windows build is unsigned (SmartScreen says "Unknown publisher") — cert costs $70/yr, buying one after ~100 installs.
> 2. No iOS/Android. Desktop-first by design, but open to being convinced.
> 3. Model picker UI is bare-bones. Rebuilding the onboarding flow next week.
> 4. No team features, no cloud sync. That's the point — but tell me if it's a dealbreaker.

## Reply playbook

- **"Why not just use [ChatGPT/Claude]?"** → "Because I don't want my contract drafts or personal messages in someone else's training data. Also no internet needed on a plane."
- **"9 tones but Grammarly has 30"** → "Good call — which 3 would you want next?"
- **"0.8 GB model is a lot"** → "Smallest is 400 MB (Qwen 2.5 0.5B). Still bigger than a cloud call, yeah. Tradeoff for privacy."
- **"How is this different from [competitor]?"** → "Offline + free + open source. Pick any two — everyone else only hits one."
