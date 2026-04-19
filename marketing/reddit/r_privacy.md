# r/privacy

**Subreddit:** https://www.reddit.com/r/privacy/
**Rules:** Extremely strict on self-promo. Lead with the problem, not the product. Link in comments, not title.
**Flair:** "Software"

---

## Title

> Every AI writing tool sends your text to a cloud server. I got annoyed enough to build a free one that doesn't.

## Body

I use AI to rephrase stuff all day — tone down angry emails, tighten
Slack messages, fix my terrible first drafts. I kept hitting the same
problem: **every mainstream tool that does this streams your text over
the internet.**

- Grammarly: all text goes to their servers, training policy opaque
- Microsoft Copilot: all text to Microsoft + shared with OpenAI
- Wordtune: all text to their servers, subscription-only
- ChatGPT/Claude: obvious — cloud by definition
- Apple Intelligence: mostly on-device, but "Private Cloud Compute"
  still sends some requests to Apple servers and the fallback to
  ChatGPT is explicit

For personal messages, legal drafts, medical notes, anything a lawyer
would say "don't put in someone else's database" — this is a problem.

So I built **Rephraser**, a menu bar / tray app where you hit a shortcut
and the rephrase happens **entirely on your laptop.** No cloud. No API
keys. No account.

**Proof, not promises:**
- MIT license, full source at github.com/vatsan95/Rephraser
- Runs on Apple MLX (Mac) / llama.cpp (Windows) — both open inference
  runtimes, both on-device-only
- Works with airplane mode on. Try it.
- Analytics opt-out, and when on, **never** reports text content, clipboard,
  file paths, or IP. Payload is literally: "rephrase happened, mode=casual,
  model=gemma-3-1b, os=windows". That's it.
- Crash reports same story — strip PII before send, off by default.

**The tradeoffs you should know**
1. The model is a 0.4–2.5 GB one-time download (you pick).
2. Smaller models (Qwen 2.5 0.5B) are worse than GPT-4 at creative
   rephrasing. For routine tone shifts and tightening? They're fine.
3. Uses ~1.5 GB RAM while model is loaded. Idle state is ~150 MB.

I'm not claiming Rephraser is the best rephraser. I'm claiming it's
the most private one that actually works, and it's free.

Site + download: [see comment below]

## First comment (where the link goes)

> Download + source: https://vatsan95.github.io/Rephraser/ — Mac and Windows, no sign-up wall, no email gate on the source repo. Privacy policy: https://vatsan95.github.io/Rephraser/privacy.html

## Reply playbook

- **"How do we know it's really offline?"** → "Two ways: (1) read the source, analytics.rs has the only HTTP client in the code path, (2) run it with your Wi-Fi off."
- **"What about telemetry when Wi-Fi is on?"** → "Off by default (Windows) / toggle-off in Settings (Mac — aligning both in v1.1). Wire-sniff it, only endpoint is TelemetryDeck analytics, zero text."
- **"Apple Intelligence also does on-device."** → "Mostly. Fallback to Private Cloud Compute + ChatGPT is explicit in Apple's own docs. Rephraser has no fallback path. If the model isn't loaded, it errors; it does not reach out."
