# Rephraser launch playbook

Everything below is ready to copy-paste. Written to sound like you, not like
marketing. Reddit in particular **deletes marketing-speak** on sight — the
copy here leads with the problem, not the product.

## Golden rules

1. **Never cross-post the same text.** Each post is tailored to the sub/site.
2. **Reply to every comment for the first 6 hours.** Algorithmic boost on
   Reddit + HN is mostly engagement velocity in the first hour.
3. **Never defend, always thank.** Someone says it's "just another AI
   wrapper"? Thank them and ask what would make it not feel like one.
4. **Screenshot > words.** Every post gets a GIF or screenshot. Use the
   ones in `docs/screenshots/`. Video script in `video/demo_script.md`.
5. **Launch order matters.** Start slow (small subreddit → feedback → fix
   typos → big one). See "Suggested order" below.

## Suggested order (7-day launch)

| Day | Platform | Why first/last |
|-----|----------|---------------|
| 1 mon | r/SideProject | Lenient mods, honest builder crowd, catches typos before bigger launches |
| 1 mon | Indie Hackers journey post | Long-form permalink, SEO-indexed, links back to site |
| 2 tue | r/LocalLLaMA | Technical validation — they'll find stack issues before HN does |
| 3 wed | Twitter / X launch thread | Low-effort, shareable, drives 1–2% of sidecar traffic |
| 3 wed | LinkedIn post | Professional network, especially useful if you ever job-hunt |
| 4 thu | r/privacy + r/opensource | Angle = on-device + MIT, not "productivity" |
| 4 thu | Dev.to technical deep-dive | SEO compounding asset, links to site |
| 5 fri | **Show HN** | Peak engagement window (Tue–Thu US mornings). Post 8–10am PT. |
| 5 fri | r/Windows11 / r/Windows10 | Timed to Windows release energy from HN |
| 6 sat | Product Hunt relaunch | Windows angle — PH allows separate platform launches |
| 6 sat | r/macapps + r/productivity | Catch weekend browsers |
| 7 sun | Email outreach to 5–10 journalists | Follow-up wave |

## Pre-launch checklist

- [ ] `docs/og-image.png` exists (social-card preview). Currently a TODO —
      make a 1200×630 PNG showing the Rephraser logo + "Free. Offline. AI."
      tagline. Free templates at canva.com/create/og-images.
- [ ] Demo GIF at `docs/screenshots/demo.gif` (≤5 MB, 10–15 sec loop).
      Record on Mac with QuickTime / Windows VM with ShareX. Script in
      `video/demo_script.md`.
- [ ] GoatCounter events seeded: all launch links have `?ref=<platform>`
      query strings. Already wired in `trackEvent()`.
- [ ] Website has the `/blog/grammarly-alternative.html` page live (it is
      after this commit). Linked from hero CTA? Not required.
- [ ] GitHub repo has Topics set: `llm`, `ai`, `tauri`, `swift`, `rust`,
      `gemma`, `offline`, `privacy`, `productivity`, `macos`, `windows`,
      `grammarly-alternative`. (Topics drive github.com search.)

## Per-post files

- `reddit/r_sideproject.md` — main casual launch
- `reddit/r_localllama.md` — technical/llama.cpp crowd
- `reddit/r_opensource.md` — MIT + "freemium is a lie" angle
- `reddit/r_privacy.md` — on-device + telemetry policy
- `reddit/r_windows11.md` — Windows-specific (Copilot alt)
- `reddit/r_productivity.md` — workflow angle
- `reddit/r_macapps.md` — Mac release
- `hackernews/show_hn.md` — title, body, first-comment
- `producthunt/launch_kit.md` — full Windows relaunch kit
- `social/twitter_thread.md` — launch thread + standalone tweets
- `social/linkedin_post.md` — professional version
- `longform/indiehackers_journey.md` — "Mac-only to cross-platform" post
- `longform/devto_technical.md` — SEO deep-dive, Tauri + llama.cpp
- `email/journalist_outreach.md` — cold email template
- `video/demo_script.md` — 60-second demo, frame-by-frame

## What happens after

Week 2+: respond to feedback, ship fixes fast (Rephraser is small enough
that a 30-line fix from a Reddit comment can ship in 2 hours via the API
push pattern you already have). Fast response is your entire moat vs
Grammarly — use it.
