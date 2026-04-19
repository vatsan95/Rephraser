# r/productivity

**Subreddit:** https://www.reddit.com/r/productivity/
**Tone:** Workflow-focused. Show the before/after, not the tech.
**Flair:** "Technique"

---

## Title

> I save ~15 minutes a day by having AI rephrase my Slack messages before I hit send. Built the tool after hitting Grammarly's paywall too many times.

## Body

This started as a hack: before I send anything semi-important on Slack,
I run it through ChatGPT and ask "make this clearer and less defensive."
Worked great. Took 45 seconds per message. That's a lot of alt-tab.

I built a tool that makes it one keystroke.

**My workflow now**
1. Draft the message in Slack / Outlook / wherever
2. Select the text
3. Hit `⌥⇧R` (Mac) / `Ctrl+Alt+R` (Windows)
4. Panel pops up, shows a rewrite, hit Enter to replace
5. Send

I picked 9 presets based on what I actually use:
- **Professional** — for emails to people senior to me
- **Casual** — for Slack replies so I don't sound like a lawyer
- **Concise** — for DMs, cuts 40% on average
- **Friendly** — for "hey can you do X" asks
- **Confident** — for pushback that doesn't start with "sorry but"
- **Shorter / Longer / Fix Typos / Creative** — self-explanatory

The thing I didn't expect: **context-aware auto-mode**. Open Slack, it
defaults to Casual. Open Outlook, it defaults to Professional. Open VS
Code, it defaults to Concise (for code comments). You don't have to
pick — it guesses and you can override.

**Tradeoffs to know**
- Runs a local AI model. One-time 400 MB–2.5 GB download depending on
  which model you pick. No internet needed afterward.
- Free, MIT licensed, no account, no premium tier.

Works on Mac and Windows. Linux if someone wants to port it.

https://vatsan95.github.io/Rephraser/

**Question back at you:** what's the one text-rewriting task you do
every day that a 0.8 GB model should be able to handle? I'm compiling a
list of modes to add.

## First comment

> Data I've been tracking on myself since I started using it internally in Feb: median rephrase time is 1.4 seconds, and I accept the first suggestion ~70% of the time. The 30% I reject are mostly cases where the model oversimplifies technical content. Bigger models (4B+) fix most of that but use more RAM.
