# Twitter / X launch content

Each tweet is under 280 chars. The thread reads as a coherent post if
someone expands it; each tweet also works standalone.

---

## Launch thread (6 tweets)

**1/ (the hook)**
> I was paying Grammarly $12/mo and realised my text was being shipped to their servers.
>
> So I spent 6 months building a free offline alternative that runs on your laptop.
>
> Rephraser — Mac + Windows, MIT licensed, no cloud.
>
> [link]
>
> [GIF of rephrase happening]

**2/ (the stack)**
> The stack:
>
> Mac → Swift + SwiftUI + Apple MLX (8 MB app)
> Windows → Rust + Tauri 2 + llama.cpp (15 MB MSI)
>
> Pick a model at first launch: Gemma 3 / Qwen / Phi-4 / Llama 3.2.
>
> No Electron. No cloud. No account. No upsell.

**3/ (the workflow)**
> The workflow that saves me ~15 min/day:
>
> Select text → hit ⌥⇧R (Mac) or Ctrl+Alt+R (Win) → panel pops up with a rewrite → Enter to paste.
>
> Works in Word, Outlook, Slack, Chrome, VS Code. Anywhere Ctrl+C works.

**4/ (the philosophy)**
> 9 rephrase tones:
> - Professional (for senior emails)
> - Casual (for Slack without sounding like a lawyer)
> - Concise (cuts 40% on average)
> - Friendly / Confident / Creative / Shorter / Longer / Fix typos
>
> + custom modes. Context-aware: softens in Slack, tightens in Outlook.

**5/ (the free-ness)**
> Free forever. No premium tier.
>
> Source: MIT. Every dep license-audited in CI.
> Telemetry: opt-out, content never reported.
> Crash reports: same story, text scrubbed.
>
> The app cannot send your text anywhere. That's the whole point.

**6/ (the ask)**
> Rephraser for Mac: [link/mac]
> Rephraser for Windows beta: [link/windows]
> Code: github.com/vatsan95/Rephraser
>
> Would love feedback on what mode to add next.
>
> Free to try. Takes 30 seconds. RT appreciated 🙏

---

## Standalone tweet variants (for when you don't want to post a thread)

**The numbers tweet:**
> Built a free, offline AI text rewriter for Mac + Windows.
>
> - 15 MB installer
> - ~150 MB RAM idle
> - 1.4s median rephrase
> - MIT licensed
> - $0/mo forever
> - runs with wifi off
>
> [link]

**The vs tweet (high engagement):**
> Grammarly: cloud, $12/mo
> Copilot: cloud, account required
> Wordtune: cloud, subscription
> ChatGPT: cloud, obvious
> Apple Intelligence: mostly on-device, falls back to cloud
>
> Rephraser: on-device only, free, MIT
>
> [link]

**The demo tweet (the GIF does the work):**
> One shortcut. Any app. Runs on your laptop. Free.
>
> [15-sec demo GIF: select Slack text → ⌥⇧R → panel appears → Enter → rewritten]
>
> rephraser: [link]

**The "why I built it" tweet:**
> I built Rephraser because I kept pasting contract language into ChatGPT and realising that was a terrible idea.
>
> It's a free offline AI rewriter for Mac + Windows. No cloud. No account. MIT.
>
> Gave myself the tool. Now giving it to you.
>
> [link]

---

## Reply templates

**For quote-tweets saying "this is just Grammarly":**
> The difference is where the inference happens. Grammarly = their server. Rephraser = your laptop. Open the Network tab, you won't see outbound traffic.

**For "how does this differ from LM Studio / Ollama?"**
> LM Studio + Ollama are chat interfaces — you alt-tab to them. Rephraser is system-wide, one keystroke, in-app. Different UX pattern, same backend (llama.cpp on Win).

**For "is the model good enough?"**
> For tone/tightening: yes. For creative rewriting: 4B models are decent, 0.5B models are weaker than GPT-4. Catalog lets you pick.

---

## Hashtags (use sparingly, 1–2 max per tweet)

Strong: #privacy #opensource #AI #macOS #Windows
Avoid: #GPT4 #ChatGPT #AIwriting (low SNR, mostly bots)
