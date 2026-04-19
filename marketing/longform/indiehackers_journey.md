# Indie Hackers journey post

**URL:** https://www.indiehackers.com/post/new
**Tone:** Personal, numbers-forward, no marketing speak. IH readers want to learn something useful.
**Length:** 800–1,500 words is the sweet spot.

---

## Title

> From Mac-only to cross-platform in 5 weeks, without owning a Windows machine

Alt titles:
- How I shipped a Windows port with zero Windows hardware (GitHub Actions + free VMs)
- Six months building a free offline AI tool: what I got right, what I'd redo

## Post

I ship solo. Last November I shipped Rephraser for Mac — a menu bar app
that rewrites selected text anywhere with one keystroke, entirely offline
using Apple MLX. Got ~800 downloads the first month.

What kept coming back in the feedback was: "This is great, do Windows."

The problem: **I don't own a Windows machine.** Not because of
principle — my budget is tight and a second laptop wasn't happening.

I shipped the Windows port 5 weeks later. Here's what worked, what
didn't, and the exact infrastructure I used so you can copy it if
you're stuck in the same spot.

## The stack decision that mattered most

Mac is Swift + SwiftUI + Apple MLX. None of that runs on Windows. I
had to start over.

Options I considered:
- **Electron** — easiest, but I refuse to ship a 100 MB app for a tool
  that runs one keystroke.
- **.NET MAUI / WPF** — Microsoft native, but inference story is
  terrible (ONNX Runtime is slower than llama.cpp, and the C# llama.cpp
  bindings are immature).
- **Tauri 2 + Rust + llama.cpp** ← picked this.

Why Tauri won:
- 15 MB installer. Mac's DMG is 8 MB. Same ballpark.
- Rust + llama-cpp-2 bindings are production-ready.
- Tauri 2 has built-in tray, single-instance, auto-updater, store.
- CI builds on GitHub's `windows-latest` runner without me touching a
  Windows box.

## The "no Windows hardware" toolchain

Everything below is free. I used all of it at various points.

**1. GitHub Actions `windows-latest` runners**
Free for public repos. 4-core, 16 GB RAM, 14 GB SSD, includes WiX (MSI
builder), NSIS, signtool, Chocolatey. Every push triggers a full
MSI + NSIS build. This caught ~70% of regressions before I ever saw a
real VM.

**2. Microsoft's free 90-day Windows dev VM**
developer.microsoft.com/en-us/windows/downloads/virtual-machines

This is my primary manual test environment. Fresh Windows 11 + Visual
Studio + Edge. 20 GB download, 90-day license, re-download when it
expires. I run it in UTM on my Mac (free). Zero dollars.

**3. Free Win10 IE10 VMs from Microsoft**
developer.microsoft.com/microsoft-edge/tools/vms
Older (Windows 10 1809+), but great for testing the minimum supported
OS.

**4. Beta testers on Reddit**
Posted in r/beta and r/SideProject asking for 5 Windows users. Got 12.
Set up a private Discord channel, shared nightly builds via GitHub
Release artifacts. Best bug reports of my career — people who actually
use their PCs for work, not my synthetic test cases.

**5. Windows Sandbox (Pro/Enterprise editions only)**
If you have access to a Windows Pro machine (anywhere — friend, work,
library), Sandbox is a clean disposable VM that launches in 5 seconds.
Worth it for smoke-testing installers before I pushed tagged releases.

**Budget:** $0. If budget allowed, Parallels on Mac ($100 one-time) or
Windows 365 Cloud PC (~$30/mo) would have been faster. Didn't need them.

## The unexpected wins

**1. CI-first development forces you to be disciplined.**
I couldn't "just try something" on a local Windows box. Every change
had to compile clean on the runner, pass clippy, pass cargo-deny,
produce an MSI under 15 MB, be VirusTotal-scanned. I never had the
luxury of commenting out a test to ship faster.

Paradoxically, this made the codebase cleaner than the Mac one.

**2. Rust forces the bugs out early.**
Mac app has had 2–3 memory bugs in 6 months. Windows build has had 0
crashes reported by beta testers in 5 weeks. The borrow checker +
`cargo clippy -- -D warnings` + `cargo-deny` is absurdly high-leverage
when you can't just hit "Run" and poke at it.

**3. Sharing between platforms is easier than people claim.**
The 9 rephrase mode prompts live in `shared/prompts/modes.json` and are
loaded by both Mac (Swift codable) and Windows (Rust serde). I don't
have to remember to sync changes. The model catalog is similar.

## The unexpected losses

**1. Debugging unfamiliar OS quirks from 3,000 miles away.**
Beta tester: "The hotkey doesn't work in Outlook 2019 on Windows 10
1809." I cannot reproduce this. I have to guess. Turned out to be UIPI
blocking `SendInput` because Outlook was running with slightly
elevated integrity. I fixed it by documenting the workaround, not by
coding around it. Spent 2 days I didn't have on this.

**2. AV false positives eat PR budget.**
Rust apps that use `SendInput` + clipboard read trigger Microsoft
Defender, Avast, Kaspersky heuristics. My release-day Reddit post
had three separate "this is malware" comments within the first hour
before I could respond. I now link the VirusTotal scan in every
release note.

**3. Code signing costs real money.**
Certum OSS cert is $70/yr. EV cert is $300+/yr. I've postponed the
cert until I hit 100 installs. Every Windows user in the meantime
walks past a SmartScreen "Unknown publisher" warning with a
"More info → Run anyway" instruction. I've lost a double-digit
percentage of downloads to this. Real cost of shipping unsigned.

## The numbers (5 weeks in)

- Windows-line code: ~4,800 lines Rust + ~1,200 lines React/TS
- Mac-line code for comparison: ~6,200 lines Swift
- Installer size: 15 MB (MSI + NSIS both under budget)
- Idle RAM: 148 MB (target was <150)
- First-token latency: 1.2s on dev VM with Gemma 3 1B (target was <1.5)
- GitHub Actions cost: $0 (public repo, free tier)
- Other costs: $0

## Launch day punch list

I'm launching on Reddit / HN / Product Hunt over the next 7 days.
Playbook checked into the repo at `marketing/README.md` if anyone
wants to steal it — every post is pre-written, timing is laid out,
reply templates included.

## What I'd redo

**1. I'd have picked Tauri on day 1 even for Mac.**
Shipping two codebases was the right call for v1 native feel, but the
shared code ceiling is higher than I thought. If I started over, I'd
do Tauri on both + MLX via FFI on Mac only. Saves ~40% of total work.

**2. I'd have bought the Certum cert before launch.**
$70 to avoid a SmartScreen warning is a no-brainer in retrospect. I was
waiting for "traction" to justify the cost; the cost was slowing the
traction.

**3. I'd have recruited beta testers 3 weeks earlier.**
Their feedback was worth more than any CI coverage. Recruit early,
even if the product is embarrassing.

## Try it

Rephraser (Mac + Windows, free, MIT): https://vatsan95.github.io/Rephraser/

Source: https://github.com/vatsan95/Rephraser

Ask me anything in the comments — especially on the CI-only Windows
workflow, which I think is underused.
