# r/Windows11 (and duplicate to r/Windows10 with tiny tweaks)

**Rules:** Moderators are strict. Post must be Windows-specific (not just "an app that happens to run on Windows"). No repost for 30 days. Flair required.
**Flair:** "Tip / How-to" or "Productivity"

---

## Title

> Built a free Windows alternative to Copilot/Grammarly that runs 100% offline — no Microsoft account, no subscription, no data leaving your PC

## Body

Microsoft Copilot is great if you're fine sending every sentence you
write to Microsoft + OpenAI. I'm not. Grammarly is $12/mo. Both ship your
text to the cloud. So I built a Windows-native alternative.

**Rephraser for Windows** — tiny tray app, one keystroke rephrase, entirely
on-device.

**How it works**
1. Install: 3.1 MB NSIS setup, per-user (no admin required)
2. First launch: pick a model (Gemma 3 1B / Qwen / Phi-4 Mini / Llama 3.2)
3. Download runs ~0.4 GB to ~2.5 GB depending on pick (one-time)
4. Select text in any app, hit `Ctrl + Alt + R`, panel appears over your work
5. Enter = paste rewrite. Escape = cancel. Your original clipboard is preserved.

**What's native about it**
- Written in Rust + Tauri 2 — not Electron. Installer is **15 MB**, idle
  RAM is **~150 MB**. Compare to Grammarly's Electron desktop app
  (~250 MB installer, ~500 MB RAM idle).
- Works in Word, Outlook, Chrome, Edge, Slack, Discord, Teams, VS Code,
  Notepad — anything where Ctrl+C works, Rephraser works.
- Handles WebView2 setup in the installer. Signed / unsigned support
  via SmartScreen walkthrough in the readme.
- MSI build available for `/quiet` silent install (IT admins welcome).
- Supports Windows 10 version 1809+ and Windows 11. x64 only in v0.1.
  ARM64 (Snapdragon X / Copilot+ PCs) targeted for v0.2.

**What it explicitly doesn't do**
- Does not grammar-check. (Grammarly's still better at that.)
- Does not translate. (Use DeepL.)
- Does not write from scratch. (Use ChatGPT.)
- It **rephrases** — takes text you wrote and rewrites it in a different
  tone. Professional / casual / concise / friendly / 6 others.

**Known rough edges in v0.1 beta**
- SmartScreen says "Unknown publisher" because the EXE isn't code-signed.
  A cert costs $70/yr from Certum — I'll buy one after 100 installs.
  Click "More info" → "Run anyway" and Windows whitelists it. Every
  release is scanned publicly by VirusTotal in CI; links in release notes.
- No tray menu yet (settings open via first-run window). Polishing next
  week.

**Download**
https://vatsan95.github.io/Rephraser/windows.html

Source: https://github.com/vatsan95/Rephraser (MIT)

Happy to answer anything about the Windows port — it's ~4 weeks old.

## First comment

> Why not MSIX / Microsoft Store? It's on the roadmap for v0.3 — Store needs MSIX + Partner Center registration ($19 one-time, fine), but I want one or two bug-fix releases under a larger user base before committing to Store review timing. NSIS exe + MSI for now.

## Reply playbook

- **"SmartScreen is scary"** → "Yep. Certum OSS cert ($70/yr) on the buy list after 100 installs. See the [walkthrough with screenshots](https://vatsan95.github.io/Rephraser/windows.html#install)."
- **"Why not just use Copilot?"** → "Copilot's great if you're fine with Microsoft + OpenAI reading what you type. For personal / legal / medical / financial writing, not acceptable."
- **"AV flagged it"** → "Rust apps that use `SendInput` + clipboard get heuristic false positives. Every build is VT-scanned; <3 engines flagging is normal."
