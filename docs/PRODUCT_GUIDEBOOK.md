# Rephraser — Product Guidebook

*Last updated: April 12, 2026*
*Status: Public Beta*

---

## 1. What This Is

Rephraser is a macOS menu bar utility. Select text anywhere, press `⌥⇧R`, get a polished version. AI runs on-device via Apple MLX. No accounts, no API keys, no cloud, no cost.

**One-liner:** "Better writing in any app, with a single keystroke."

---

## 2. Current State: Honest Assessment

### What's solid (ship-ready)
- Core rephrase flow: hotkey → capture → stream → panel → paste. Works reliably.
- 5 preset modes with well-crafted system prompts + custom mode support.
- 5 downloadable models (Gemma 4 recommended). Download/load/delete lifecycle is clean.
- Clipboard handling is bulletproof — original clipboard always restored.
- Privacy story is strong — text never leaves the device.
- Floating panel feels native, streaming UX is smooth.
- Error handling is comprehensive with user-friendly messages.

### What's broken or incomplete
| Issue | Severity | User Impact |
|-------|----------|-------------|
| "Play sound" toggle does nothing | High | Users click it, nothing happens. Erodes trust. |
| "Launch at login" toggle does nothing | High | Same — setting exists but is a lie. |
| "Check for Updates" button does nothing | High | Users can't get patches. |
| Keyboard shortcut is not customizable | Medium | Displayed as read-only `⌥⇧R`, no recorder UI. |
| No inference timeout | Medium | If model hangs, UI freezes indefinitely. |
| Sparkle appcast URL is a placeholder | High | Auto-update will never work until configured. |
| `RephraseResult` struct exists but is never used | Low | Dead code, no rephrase history. |
| PRD says API-based; app is on-device | Info | Documentation is stale. |

### The rule of thumb
**If a toggle or button exists in the UI, it must work.** A broken toggle is worse than no toggle. Either implement it or remove it before v1.0 stable.

---

## 3. User Journey (Current)

```
Install → Launch → Onboarding (2 screens) → Menu bar ready
                                    ↓
                    [Model auto-downloads in background]
                                    ↓
            Select text → ⌥⇧R → Panel → Accept/Reject
```

**Time to first rephrase:** ~60 seconds + model download time (~2-5 min on good internet).

**Friction points remaining:**
1. Accessibility permission requires leaving the app to System Settings — unavoidable but jarring.
2. If user skips accessibility, the app looks "ready" but won't work. No blocker, just an error on first try.
3. No guided first rephrase — user must figure out the workflow themselves.

---

## 4. Architecture (For Technical PMs)

```
┌─────────────────────────────────────────────────┐
│  RephraserApp (entry point)                      │
│  └─ AppDelegate                                  │
│      ├─ AppState (@Observable, persistent)       │
│      ├─ ModelManager (@Observable, MLX lifecycle) │
│      └─ RephraseCoordinator (state machine)      │
│          ├─ HotkeyService (global ⌥⇧R)          │
│          ├─ TextCaptureService (Cmd+C/V sim)     │
│          ├─ RephraseService (MLX inference)       │
│          └─ SourceAppTracker (refocus)           │
└─────────────────────────────────────────────────┘

State Machine:
  idle → capturing → rephrasing → showingResult → pasting → idle
                                → showingError → idle
```

**Key design decisions:**
- `@MainActor` everywhere — no concurrency bugs, at the cost of some theoretical perf.
- `AsyncThrowingStream` for streaming — same interface the old API providers used. Clean swap.
- `ClipboardSnapshot` captures ALL pasteboard types (text, RTF, images, files) — not just text.
- `NSPanel` (not `NSWindow`) — floats above fullscreen, doesn't steal focus, non-activating.

**File count:** 22 Swift files, ~2,500 lines total. Small, readable codebase.

---

## 5. What to Ship Next

### 5a. Before v1.0 Stable (blockers)

**Remove or implement the three broken stubs.**
These are the highest-priority items because they damage user trust.

| Stub | Recommendation | Effort |
|------|---------------|--------|
| Sound toggle | Implement: play `NSSound.beep()` or system sound when rephrase completes. 5 lines of code. | 15 min |
| Launch at login | Implement: use `SMAppService.mainApp.register()` (macOS 13+). ~10 lines. | 30 min |
| Check for Updates | Wire: call `updaterController.updater.checkForUpdates()`. 1 line. But also need a real appcast URL on GitHub Releases. | 1 hour |

**Add inference timeout.**
If the model hangs or generates forever, the user is stuck. Add a 30-second timeout on the rephrase task. If exceeded, show "Rephrase timed out" error with retry.

**Update the PRD.**
`docs/PRD.md` still describes an API-based architecture with OpenAI/Anthropic providers. Rewrite it to match the on-device MLX reality. Stale docs cause confusion for contributors.

### 5b. v1.1 — Polish

| Feature | Why | Effort |
|---------|-----|--------|
| Keyboard shortcut customization | Power users expect it. `HotkeyService` already has `register(key:modifiers:)`. Need a ShortcutRecorder UI. | Medium |
| Rephrase history | Save last 20 rephrases. One-click reuse. Uses the existing `RephraseResult` struct (currently dead code). | Medium |
| Soft text limit warning | Warn at 2,000 chars before hard-rejecting at 8,000. Reduces surprise. | Small |
| Guided first rephrase | After onboarding, show a tooltip: "Try it! Select text and press ⌥⇧R". Disappears after first success. | Small |

### 5c. v2.0 — Expansion

| Feature | Notes |
|---------|-------|
| iOS companion app | Share custom modes via iCloud. Different UX (share sheet, not hotkey). |
| Apple Intelligence integration | When Apple ships on-device models in macOS, offer as a provider option. |
| Context-aware mode | Auto-detect "Slack" → Casual, "Gmail" → Professional. Use `SourceAppTracker` bundle ID. |
| Multilingual UI | App UI in multiple languages. Model already handles multilingual input. |

---

## 6. Competitive Positioning

| Competitor | How Rephraser wins |
|------------|-------------------|
| Grammarly | Lighter (menu bar vs. browser extension), system-wide (not just browsers), free, private. |
| ChatGPT app | Rephraser is purpose-built for one task. No chat window, no context switching. One shortcut. |
| QuillBot | No browser tab needed. Works in native apps. On-device = no subscription. |
| Apple Writing Tools | More modes, custom modes, open-source, model choice. Apple's is limited to their models. |

**Positioning statement:**
> Rephraser is the fastest way to improve any text on your Mac. One shortcut, instant result, completely private. No accounts, no subscriptions, no cloud.

---

## 7. Target Users

**Primary:** Knowledge workers who write in English across multiple apps daily.
- Slack/Teams power users who want to sound professional quickly
- Non-native English speakers who want grammar and tone correction
- Writers/students who want concise or elaborate rewrites

**Secondary:** Privacy-conscious users who refuse cloud AI.
- Security-minded professionals
- Regulated industries (legal, healthcare) where text can't leave the device

**Anti-target:** Users who need document-level rewriting, translation, or creative writing. This is a sentence/paragraph tool, not a document tool.

---

## 8. Metrics That Matter

### Activation (first 5 minutes)
- **Onboarding completion rate** — target: >90%
- **Accessibility grant rate** — target: >80% (some will skip)
- **Model download completion** — target: >85%
- **First rephrase within 24h** — target: >70%

### Engagement (weekly)
- **Rephrases per active user per week** — north star metric. Target: >10.
- **Accept rate** — % of rephrases accepted vs. rejected. Target: >75%. Below 50% = quality problem.
- **Mode distribution** — which modes get used. Informs default selection.
- **Re-rephrase rate** — how often users switch modes and retry. High = users exploring. Very high = first result bad.

### Reliability
- **Error rate** — % of hotkey presses that end in error. Target: <3%.
- **Crash rate** — target: 0%.
- **Inference latency (p50, p95)** — time from hotkey to first token. Target: p50 <2s, p95 <5s.

### Retention
- **D1, D7, D30 retention** — classic cohort analysis.
- **Churn reason** (from GitHub issues) — model quality? speed? UX friction?

*Note: No telemetry is implemented yet. These metrics would come from opt-in analytics (Phase 2) or GitHub issue patterns.*

---

## 9. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Model quality disappoints users | Medium | High | Offer multiple models. Make switching easy. Default to best (Gemma 4). |
| Accessibility permission scares users | Medium | Medium | Clear explanation in onboarding. "Required for copy/paste" not "we read your screen." |
| Model download too slow/large | Medium | Medium | Show clear progress. Smallest model is 1.8 GB. Offer choice. |
| Apple blocks non-sandboxed apps | Low | Critical | Monitor Apple's notarization policies. App sandbox is OFF (required for Accessibility). |
| Clipboard managers interfere | Low | Medium | Document known issues. Test with popular clipboard managers. |
| MLX framework breaking changes | Medium | Medium | Pin dependency version. Test before upgrading. |
| Competitor ships native macOS feature | Medium | High | Apple Writing Tools exists but is limited. Differentiate on model choice + custom modes. |

---

## 10. Open Questions

These need answers before v1.0 stable:

1. **Distribution:** DMG on GitHub Releases? Homebrew cask? Mac App Store is ruled out (no sandbox). What's the install path?

2. **Code signing:** Is an Apple Developer account set up? Unsigned apps trigger Gatekeeper warnings. Users have to right-click → Open. This kills conversion.

3. **Appcast URL:** Sparkle needs a real appcast.xml hosted somewhere. GitHub Releases is the obvious choice. Is CI/CD set up for releases?

4. **Model freshness:** When new/better models come out (Gemma 5, etc.), how do we update the catalog? App update? Remote config?

5. **Feedback channel:** GitHub Issues is fine for developers. But target users are knowledge workers, not devs. Need a lighter feedback mechanism (email? Discord?).

6. **Legal:** MIT license is fine for code. But shipping pre-configured HuggingFace model IDs — are those models' licenses compatible? Gemma 4 is Apache 2.0 (fine). Llama 3.2 has a custom license (check usage terms). Qwen is Apache 2.0 (fine). Phi-4 is MIT (fine).

---

## 11. Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-04-12 | Pivot from cloud APIs to on-device MLX | AI models small enough to run locally. Eliminates cost, API keys, and privacy concerns. |
| 2026-04-12 | Gemma 4 E4B as default model | Google's latest, best quality at 4B size class, released April 2, 2026. |
| 2026-04-12 | Simplify onboarding from 4 steps to 2 | Remove model picker and mode selector. Auto-download recommended model. Default to Professional mode. |
| 2026-04-12 | Strip all OpenAI/Anthropic code | Clean break. No hybrid approach. On-device only for v1. |
| 2026-04-12 | MIT license, open source | Free product, community-driven development. |
