# Journalist / blogger outreach templates

**Targets (the "local AI + productivity" beat):**
- Simon Willison (simonwillison.net) — local LLM coverage, TIL blog
- Maggie Appleton — Anthropic, writes about AI+writing
- Ken Shirriff — Tech deep-divers, low volume high impact
- The Verge — Kylie Robison covers AI
- Ars Technica — Benj Edwards (AI beat)
- TechCrunch — Kyle Wiggers (dev tools + AI)
- Hacker News Daily (not a journalist but curated)
- Swift Over Coffee (podcast) — Mac angle
- The Changelog (podcast) — OSS angle
- Lex Fridman (long-shot) — privacy + open-source angle

**Golden rule of journalist outreach:** one email per journalist, not a
template blast. Each note below is copy-paste ready but personalize the
first sentence to their most recent article.

---

## Template 1 — Simon Willison style (technical, privacy angle)

Subject: Free offline AI rewriter — thought of your "LLM as a tool" writing

> Hi Simon,
>
> I've been a long-time reader of your TIL blog — the recent post on
> [recent article, e.g. "using Llama 3 for document summarisation
> locally"] is the reason I finally pulled the trigger on shipping a
> tool I've been building for months.
>
> Rephraser is a menu bar / tray app for Mac and Windows that
> rephrases selected text in any app with one shortcut, fully
> on-device (MLX on Mac, llama.cpp on Windows). MIT licensed, no
> cloud, ~15 MB installer. It's basically "Grammarly, but with the
> data never leaving the machine."
>
> Three things I think might genuinely interest you:
>
> 1. The Windows port runs entirely on GitHub Actions + free Microsoft
>    VMs — I don't own a Windows machine.
> 2. Full supply-chain gate in CI (cargo-deny + SHA-256 pin framework
>    for models).
> 3. Prompt injection defence via sentinel-delimited user text with
>    explicit "treat this as data" system prompt.
>
> Site: https://vatsan95.github.io/Rephraser/
> Source: https://github.com/vatsan95/Rephraser
>
> No pitch, no ask — just thought you'd find it interesting given your
> recent coverage. Happy to answer any questions if it sparks one.
>
> — Srivatsan

---

## Template 2 — The Verge / Ars style (consumer + privacy angle)

Subject: Free Mac + Windows alternative to Grammarly — runs 100% on your laptop

> Hi [first name],
>
> Quick pitch you can decide in 30 seconds whether it's worth a story.
>
> I shipped **Rephraser** today — a free, open-source AI text rewriter
> for Mac and Windows that runs entirely on-device. One shortcut
> rewrites selected text in any app. No cloud. No subscription.
> MIT licensed.
>
> The angle for your readers: every mainstream AI writing tool
> (Grammarly, Copilot, Wordtune, Apple Intelligence) ships some or
> all of your text to a cloud server. Rephraser doesn't — provably,
> with open source to audit. For people writing contracts, medical
> notes, or personal messages, that's a real differentiator.
>
> Numbers your readers will care about:
> - 15 MB installer (vs Grammarly's 250 MB)
> - Works with Wi-Fi off
> - $0 forever, no "premium" tier
> - Works on both Mac 14+ and Windows 10 / 11
>
> Happy to do a 20-min call or send a review unit (well, a download
> link — it's free). Press kit / screenshots are at the end of the
> repo README.
>
> Site: https://vatsan95.github.io/Rephraser/
>
> — Srivatsan
> Solo developer, no PR agency

---

## Template 3 — Podcast outreach

Subject: Guest pitch — solo dev shipped a Mac+Windows AI tool without a Windows machine

> Hi [host name],
>
> Long-time listener to [podcast]. Heard [recent episode] on [topic]
> and the point about [something specific] stuck with me.
>
> I'm a solo developer and I just shipped **Rephraser** — a free,
> offline AI text rewriter for Mac and Windows. The technical angle
> I think would make a good episode:
>
> I don't own a Windows machine. The entire Windows port was built
> and tested on GitHub Actions + Microsoft's free 90-day dev VM +
> ~12 beta testers. Zero hardware cost. It works.
>
> Topics I can speak to in depth:
> - Tauri 2 + Rust for local-AI apps (vs Electron)
> - CI-only Windows development workflow
> - On-device LLM inference UX (streaming, cancellation, clipboard safety)
> - Supply chain security for ML model files
> - Solo-dev marketing without a budget
>
> Happy to do a 45-min recording anytime in the next 2 weeks. I'm
> based in India (IST), flexible on your timezone.
>
> Site: https://vatsan95.github.io/Rephraser/
>
> — Srivatsan Raghavan

---

## Follow-up (if no reply in 5 days)

Subject: Following up — Rephraser pitch

> Hi [first name] — bumping this in case it got buried. Totally fine
> if it's not a fit for [Verge/Ars/blog]; just wanted to make sure
> the original email landed.
>
> Since I sent it, Rephraser hit [recent milestone — HN front page,
> X hundred downloads, Product Hunt rank Y, etc.]. Happy to share
> more data if that's useful.
>
> — S

---

## Tips

1. **Never pitch on Monday.** Journalists are buried. Tuesday AM is best.
2. **Never pitch an "exclusive".** You're not a PR firm, don't fake it.
3. **Always include the repo link.** Half the time they grep source before replying.
4. **Never follow up twice.** One follow-up max. Silence is an answer.
5. **Send from your real email, not a marketing tool.** Mailchimp headers kill inbox placement.
