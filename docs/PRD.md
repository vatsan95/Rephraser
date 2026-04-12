# Rephraser -- Product Requirements Document

> **Status**: v1.0 -- Pre-development  
> **Last updated**: February 9, 2026  
> **Platform**: macOS (14+ Sonoma)  
> **iOS**: Deferred to Phase 2

---

## 1. Problem Statement

macOS has built-in AI writing tools, but they only work in a handful of Apple-native apps and select third-party apps. For the vast majority of apps people use daily -- Slack, Discord, Gmail in a browser, Notion, Linear, VS Code, and dozens more -- there is no system-wide way to quickly rephrase text.

Users currently must:
- Copy text, open ChatGPT/Claude in a browser, paste, prompt, copy result, go back, paste
- Use app-specific AI features (only available in some apps)
- Just send poorly worded messages

This friction means most people don't bother rephrasing at all.

## 2. Product Vision

**Rephraser** is a lightweight macOS menu bar utility that lets users rephrase selected text in **any application** with a single keyboard shortcut. Wherever a cursor blinks and text can be typed, Rephraser works.

Think of it as "Whisper Flow, but for rephrasing instead of transcription."

### Core Value Proposition
- **Universal**: Works in every app, not just Apple-native ones
- **Fast**: One shortcut, streaming result, Enter to accept. Under 3 seconds end-to-end.
- **Non-destructive**: Preview before replacing. Escape to cancel.
- **Lightweight**: Menu bar app. No dock icon. No browser tab. No subscription service to manage.

## 3. Target Audience

**Primary**: Anyone who types on a Mac and wants to communicate better.

- Knowledge workers writing Slack messages, emails, and documents
- Non-native English speakers who want grammar and tone correction
- Developers writing PR descriptions, code reviews, and documentation
- Students writing essays, applications, and emails to professors
- Professionals who switch between formal and casual contexts frequently

**Technical expectation for v1**: Users must be comfortable obtaining an API key from OpenAI or Anthropic (BYOK model). This limits the initial audience to somewhat technical users. Phase 2 will address this with on-device AI or a hosted option.

## 4. User Stories

### US-1: Basic Rephrase
**As a** Slack user  
**I want to** select my drafted message and press a shortcut to get a more professional version  
**So that** I don't send poorly worded messages to my team

### US-2: Mode Switching
**As a** user who writes in different contexts  
**I want to** quickly switch between Professional, Casual, and Concise rephrase modes  
**So that** the tone matches the context without manual prompt engineering

### US-3: Custom Prompts
**As a** power user  
**I want to** define my own rephrase instructions (e.g., "Make it sound confident but not arrogant")  
**So that** I can tailor rephrasing to my personal communication style

### US-4: Grammar Fix Only
**As a** non-native English speaker  
**I want to** fix only grammar and spelling without changing my tone or word choices  
**So that** my writing sounds correct but still sounds like me

### US-5: Preview Before Replacing
**As a** user who values control  
**I want to** see the rephrased version before it replaces my text  
**So that** I can reject it if the AI changed the meaning

### US-6: Quick Re-rephrase
**As a** user reviewing a rephrase result  
**I want to** switch to a different mode from the result panel and get a new version instantly  
**So that** I don't have to close the panel, change modes, and trigger again

### US-7: First-Time Setup
**As a** new user  
**I want to** be guided through granting permissions and entering my API key  
**So that** I can start using the app without reading documentation

### US-8: Provider Choice
**As a** user with preferences about AI providers  
**I want to** choose between OpenAI and Anthropic (and select specific models)  
**So that** I can use the provider I trust or already pay for

## 5. Functional Requirements

### FR-1: Global Keyboard Shortcut
- **FR-1.1**: The app registers a system-wide keyboard shortcut (default: Opt+Shift+R)
- **FR-1.2**: The shortcut works in any application where text can be selected
- **FR-1.3**: The shortcut is configurable in Settings via a key recorder
- **FR-1.4**: If the shortcut conflicts with another app, the user is warned

### FR-2: Text Capture
- **FR-2.1**: On shortcut press, the app captures the currently selected text via clipboard simulation (Cmd+C)
- **FR-2.2**: The app saves the FULL clipboard state before capture (all pasteboard types: RTF, HTML, images, files, etc.)
- **FR-2.3**: The app uses adaptive polling (checking clipboard change count every 20ms, max 500ms) to detect when the copy completes
- **FR-2.4**: The original clipboard is restored immediately after reading the captured text
- **FR-2.5**: If no text is captured (empty clipboard after Cmd+C), show error: "No text selected"
- **FR-2.6**: The app records the source application's PID for later refocus

### FR-3: AI Rephrasing
- **FR-3.1**: Support OpenAI API (GPT-4o-mini, GPT-4o) and Anthropic API (Claude 3.5 Haiku, Claude 3.5 Sonnet)
- **FR-3.2**: User provides their own API key (BYOK model)
- **FR-3.3**: API keys are stored securely in the macOS Keychain
- **FR-3.4**: Responses are streamed (token-by-token) to minimize perceived latency
- **FR-3.5**: Failed requests are retried up to 3 times with exponential backoff (0.5s, 1s, 2s)
- **FR-3.6**: Requests timeout after 15 seconds
- **FR-3.7**: Text longer than 8,000 characters is rejected with an error message
- **FR-3.8**: Text longer than 2,000 characters triggers a soft warning before proceeding

### FR-4: Rephrase Modes
- **FR-4.1**: Preset modes: Professional, Casual, Concise, Elaborate, Fix Grammar
- **FR-4.2**: Each mode has a carefully crafted system prompt (see Section 9)
- **FR-4.3**: Users can create, edit, and delete custom modes with their own prompt instructions
- **FR-4.4**: A default mode is configurable (used when shortcut is pressed)
- **FR-4.5**: Mode can be changed from: (a) the floating panel dropdown, (b) the menu bar popover, (c) Settings

### FR-5: Floating Result Panel
- **FR-5.1**: A floating panel appears after the shortcut is pressed, showing the streaming AI response
- **FR-5.2**: The panel is non-activating (source app retains focus, cursor position preserved)
- **FR-5.3**: The panel floats above all windows including fullscreen apps
- **FR-5.4**: The panel shows: rephrased text, mode dropdown, Accept button, Reject button
- **FR-5.5**: Accept: Enter key or click. Reject: Escape key or click.
- **FR-5.6**: Streaming text displays with a typing cursor animation
- **FR-5.7**: While streaming, Accept is disabled until the full response arrives
- **FR-5.8**: Mode dropdown triggers a re-rephrase with the new mode (original text is retained)
- **FR-5.9**: Panel is dismissable by clicking outside it
- **FR-5.10**: Panel shows actionable error messages for all failure modes (see Section 8)

### FR-6: Text Replacement (Accept Flow)
- **FR-6.1**: On Accept, the panel dismisses
- **FR-6.2**: The source app is re-activated by PID (if not already frontmost)
- **FR-6.3**: Rephrased text is written to the clipboard
- **FR-6.4**: Cmd+V is simulated after a 50ms delay (to allow app focus)
- **FR-6.5**: The original clipboard is restored after a 200ms delay (to allow paste to complete)
- **FR-6.6**: Rephrased text is pasted as plain text. In rich text editors, it adopts the surrounding paragraph formatting.

### FR-7: Menu Bar Presence
- **FR-7.1**: App appears only in the menu bar (no Dock icon)
- **FR-7.2**: Menu bar icon provides a popover with: current mode indicator, mode quick-switcher, settings access, quit
- **FR-7.3**: Info.plist sets LSUIElement=true

### FR-8: Settings
- **FR-8.1**: General tab: default rephrase mode, launch at login toggle, menu bar icon style
- **FR-8.2**: API tab: provider selector (OpenAI/Anthropic), API key input with live validation, model selector
- **FR-8.3**: Modes tab: enable/disable preset modes, create/edit/delete custom modes
- **FR-8.4**: Advanced tab: clipboard delay (auto/manual), max text length, sound feedback toggle, check for updates
- **FR-8.5**: Keyboard shortcut recorder (custom key combination)

### FR-9: Onboarding
- **FR-9.1**: First launch shows a multi-step onboarding flow
- **FR-9.2**: Step 1: Welcome -- explains what the app does with a brief animation
- **FR-9.3**: Step 2: Accessibility permission -- visual guide to System Settings, polls AXIsProcessTrusted every 1s, auto-advances when granted
- **FR-9.4**: Step 3: API key entry -- with direct links to get keys from OpenAI/Anthropic, validates key with a test API call
- **FR-9.5**: Step 4: Choose default mode -- presents all preset modes with descriptions
- **FR-9.6**: Step 5: Guided first rephrase -- provides sample text to try the full flow

### FR-10: Auto-Update
- **FR-10.1**: App uses Sparkle framework for self-updating
- **FR-10.2**: Checks for updates on launch and periodically (configurable)
- **FR-10.3**: Appcast XML hosted on GitHub Releases
- **FR-10.4**: User is notified of available updates and can install with one click

## 6. Non-Functional Requirements

### NFR-1: Performance
- Clipboard capture to API call fired: < 500ms
- Streaming first token visible: < 1.5s (depends on API provider)
- Full rephrase (short text, ~50 words): < 3s end-to-end
- Accept to text replaced in source app: < 400ms
- App memory footprint: < 50MB resident

### NFR-2: Reliability
- Clipboard is ALWAYS restored, even if the app crashes mid-operation (best effort via defer/cleanup)
- API failures surface actionable error messages, never silent failures
- App handles loss of network gracefully (detect before API call if possible)

### NFR-3: Security
- API keys stored in macOS Keychain (not UserDefaults, not plain text)
- No telemetry, analytics, or data collection in v1
- Text is sent only to the user's chosen API provider (OpenAI or Anthropic)
- No text is stored persistently by the app (rephrase history deferred to Phase 2)
- App is code-signed with Developer ID and notarized with Apple

### NFR-4: Compatibility
- macOS 14 (Sonoma) and later
- Works with native apps (Mail, Notes, TextEdit)
- Works with Electron apps (Slack, Discord, VS Code, Notion)
- Works with browser text fields (Chrome, Safari, Firefox, Arc)
- Known limitations: terminal emulators (Cmd+C = SIGINT), password fields (blocked by OS)

### NFR-5: Distribution
- Direct distribution via signed + notarized DMG
- No App Sandbox (required for Accessibility API and CGEvent)
- Auto-update via Sparkle framework

## 7. System Prompt Specifications

### Professional Mode
```
Rephrase the following text to sound professional and polished, suitable for workplace communication.
Rules:
- Keep the same meaning and intent
- Maintain the same language as the input
- Fix any grammar or spelling errors
- Use a confident, respectful tone
- Do not add information not present in the original
- Return ONLY the rephrased text with no explanation or preamble
```

### Casual Mode
```
Rephrase the following text to sound casual and friendly, like a message to a colleague you're comfortable with.
Rules:
- Keep the same meaning and intent
- Maintain the same language as the input
- Fix any grammar or spelling errors
- Use a warm, approachable tone
- Do not add information not present in the original
- Return ONLY the rephrased text with no explanation or preamble
```

### Concise Mode
```
Rephrase the following text to be as concise as possible while preserving the full meaning.
Rules:
- Remove unnecessary words, filler, and redundancy
- Keep the same meaning, intent, and tone
- Maintain the same language as the input
- Fix any grammar or spelling errors
- Do not remove important details or nuance
- Return ONLY the rephrased text with no explanation or preamble
```

### Elaborate Mode
```
Rephrase the following text with more detail and context, making it clearer and more comprehensive.
Rules:
- Expand on the ideas naturally without adding false information
- Keep the same meaning and intent
- Maintain the same language as the input
- Fix any grammar or spelling errors
- Use smooth transitions between ideas
- Return ONLY the rephrased text with no explanation or preamble
```

### Fix Grammar Mode
```
Fix only the grammar, spelling, and punctuation in the following text. Do NOT change the wording, tone, or style.
Rules:
- Correct grammar, spelling, and punctuation errors only
- Keep the original wording as close as possible
- Do not rephrase, restructure, or change the tone
- Maintain the same language as the input
- Return ONLY the corrected text with no explanation or preamble
```

## 8. Error Handling Specification

| Error Condition | User-Facing Message | Action Button |
|---|---|---|
| Accessibility not granted | "Rephraser needs Accessibility permission to work. Click to open System Settings." | Open System Settings |
| No API key configured | "No API key set up. Add your key in Settings to start rephrasing." | Open Settings |
| Invalid API key | "Your API key was rejected by {provider}. Check it in Settings." | Open Settings |
| No text selected / captured | "No text detected. Select some text first, then press {shortcut}." | OK (dismiss) |
| Text too long (>8000 chars) | "Selection too long ({n} characters). Select a shorter passage (max 8,000)." | OK (dismiss) |
| API timeout (>15s) | "Request timed out. The AI service may be slow. Try again." | Retry / Dismiss |
| API rate limited | "Rate limited by {provider}. Wait a moment and try again." | OK (dismiss) |
| Network offline | "No internet connection. Check your network and try again." | OK (dismiss) |
| API server error (5xx) | "The AI service is having issues. Try again in a moment." | Retry / Dismiss |
| Unknown error | "Something went wrong. Try again, or check Settings if this persists." | Retry / Open Settings |

## 9. User Journey: The Slack Scenario

### Context
User has Rephraser installed, configured with OpenAI (GPT-4o-mini), default mode Professional. App is in the menu bar.

### Flow

1. **User types in Slack**: "hey john can you plz send me the report asap i need it for the meeting tomrrow"

2. **User selects text**: Presses Cmd+A to select all text in the message input

3. **User presses Opt+Shift+R**: The global shortcut triggers Rephraser

4. **Behind the scenes (~200ms)**:
   - Record Slack's PID
   - Snapshot full clipboard (all types)
   - Simulate Cmd+C
   - Poll clipboard until change detected (~50ms for Slack)
   - Read plain text
   - Restore original clipboard immediately

5. **Floating panel appears**: Non-activating panel over Slack, text streams in word-by-word:
   > "Hi John, could you please send me the report at your earliest convenience? I need it for tomorrow's meeting."

6. **User reviews**: Can Accept (Enter), Reject (Escape), or switch mode from the dropdown

7. **On Accept**:
   - Panel dismisses
   - Confirm Slack is focused (re-activate by PID if needed)
   - Write rephrased text to clipboard
   - Simulate Cmd+V (replaces selected text in Slack)
   - Restore original clipboard after 200ms

8. **Result**: Slack message box now contains the professional version. User presses Enter to send.

### Total time: ~2-3 seconds (mostly AI processing)

## 10. Technical Architecture

### Tech Stack
- **Language**: Swift 5.9+
- **UI**: SwiftUI, macOS 14+
- **Hotkeys**: HotKey (SPM) -- Carbon API wrapper
- **AI Client**: MacPaw/OpenAI (SPM) for OpenAI; raw URLSession for Anthropic
- **Keychain**: KeychainAccess (SPM)
- **Auto-Update**: Sparkle (SPM)
- **Panel**: Custom NSPanel subclass with NSHostingView

### Project Structure
```
Rephraser/
  Rephraser.xcodeproj
  Rephraser/
    RephraserApp.swift
    AppState.swift

    Coordinator/
      RephraseCoordinator.swift       -- State machine orchestrating the full flow

    Services/
      HotkeyService.swift             -- Global shortcut registration
      TextCaptureService.swift         -- Clipboard capture + CGEvent simulation
      ClipboardSnapshot.swift          -- Full pasteboard save/restore
      RephraseService.swift            -- Protocol for AI providers
      OpenAIProvider.swift             -- OpenAI streaming completions
      AnthropicProvider.swift          -- Anthropic streaming messages
      KeychainService.swift            -- Secure key storage
      SourceAppTracker.swift           -- Frontmost app PID tracking

    Models/
      RephraseMode.swift               -- Mode enum + custom mode storage
      RephraseResult.swift             -- Result struct
      APIProvider.swift                -- Provider + model enum
      AppError.swift                   -- Unified error types

    Views/
      MenuBarView.swift                -- Menu bar popover
      RephrasePanel.swift              -- NSPanel subclass
      RephrasePanelContent.swift       -- SwiftUI panel content
      SettingsView.swift               -- Tabbed settings window
      OnboardingView.swift             -- First-run flow
      Components/
        ShortcutRecorderView.swift
        APIKeyField.swift
        StreamingTextView.swift

    Utilities/
      AccessibilityHelper.swift
      CGEventHelpers.swift
      RetryHelper.swift
```

### State Machine

The RephraseCoordinator manages these states:

```
Idle
  -> CheckingPreconditions (on hotkey)
    -> Error_NoAccessibility
    -> Error_NoAPIKey
    -> CapturingText
      -> Error_EmptySelection
      -> Rephrasing
        -> ShowingResult (stream complete)
        -> Error_APIFailure
        -> Error_TooLong
        -> Error_Offline
          ShowingResult
            -> Pasting (user accepted)
            -> Idle (user rejected)
              Pasting
                -> Idle (complete)
```

## 11. Permissions

| Permission | Why | Required? |
|---|---|---|
| Accessibility | Simulate Cmd+C and Cmd+V keystrokes via CGEvent | Mandatory -- app cannot function without it |
| Network (outbound) | HTTPS calls to api.openai.com / api.anthropic.com | Mandatory |
| App Sandbox | Must be DISABLED for Accessibility/CGEvent to work | N/A (disabled) |

## 12. Known Limitations (v1)

- **Terminal emulators**: Cmd+C sends SIGINT in most terminals. Rephrase won't capture text inside terminal apps unless they map Cmd+C to copy (e.g., iTerm2 with text selected).
- **Password fields**: Most password fields block Cmd+C for security. Expected and correct behavior.
- **Clipboard managers**: The brief (~200ms) intermediate clipboard state may be captured by third-party clipboard managers.
- **Rich text formatting**: Rephrased text is plain text from the AI. In rich editors, it adopts surrounding paragraph style. Original formatting (bold words, inline links) is not carried over -- this is inherent to how rephrasing changes text structure.
- **Deselection risk**: If the user clicks in the source app while the panel is showing (it's non-activating so clicks pass through), the text selection is lost and Accept will insert rather than replace.
- **Debug builds**: CGEvent Accessibility permission applies to Xcode when running from the IDE. Must test with archived/signed builds.

## 13. Phase 2 Roadmap (Deferred)

- **iOS app**: Action Extension + Shortcuts integration for system-wide rephrasing on iPhone
- **On-device AI**: Apple Foundation Models for a free, private, zero-setup tier
- **Rephrase history**: Searchable log of past rephrases with one-click re-use
- **Per-mode shortcuts**: e.g., Opt+Shift+1 for Professional, Opt+Shift+2 for Casual
- **Context-aware mode**: Auto-detect if user is in Slack vs Mail and adjust default tone
- **Subscription tier**: Hosted AI backend for users who don't want to manage API keys
- **Crash reporting**: Sentry or similar for production debugging
- **Analytics**: Optional, privacy-respecting usage telemetry

## 14. Success Metrics (Post-Launch)

- **Activation rate**: % of downloaders who complete onboarding (grant permissions + enter API key)
- **Daily active usage**: Average rephrases per day per active user
- **Accept rate**: % of rephrases that are accepted vs rejected (quality signal)
- **Mode distribution**: Which modes are used most (informs defaults and future modes)
- **Error rate**: % of rephrase attempts that result in error states

*Note: No telemetry is implemented in v1. These metrics are aspirational for when telemetry is added in Phase 2.*

---

## Changelog

| Date | Change | Section |
|---|---|---|
| 2026-02-09 | Initial PRD created | All |
