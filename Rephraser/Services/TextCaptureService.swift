import AppKit
import ApplicationServices

// MARK: - Text Capture Service

/// Handles capturing selected text from any app via AX API or clipboard simulation,
/// and pasting rephrased text back.
@MainActor
final class TextCaptureService {
    private var savedSnapshot: ClipboardSnapshot?

    /// Maximum time to wait for clipboard to change after simulating Cmd+C
    var maxClipboardWait: Duration = .milliseconds(1500)

    /// Capture the currently selected text from the frontmost app.
    /// Uses the source app PID for direct AX queries, falls back to AppleScript Cmd+C.
    func captureSelectedText(sourceAppPID: pid_t? = nil) async -> String? {
        debugLog("captureSelectedText called, sourceAppPID=\(sourceAppPID.map(String.init) ?? "nil")")

        // Strategy 1: Direct AX API using source app PID (most reliable)
        if let pid = sourceAppPID {
            if let axText = getSelectedTextViaAX(pid: pid), !axText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                debugLog("AX (PID) capture succeeded: \(axText.prefix(50))...")
                return axText
            }
        }

        // Strategy 2: AX API via system-wide (legacy fallback)
        if let axText = getSelectedTextViaSystemWide(), !axText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            debugLog("AX (system-wide) capture succeeded: \(axText.prefix(50))...")
            return axText
        }

        debugLog("AX capture returned nil, falling back to clipboard")

        // Strategy 3: AppleScript-based Cmd+C (most compatible)
        return await captureViaClipboard()
    }

    /// Paste the rephrased text into the source app.
    func pasteText(_ text: String) async {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        try? await Task.sleep(for: .milliseconds(80))
        performPasteViaAppleScript()
        try? await Task.sleep(for: .milliseconds(200))

        savedSnapshot?.restore()
        savedSnapshot = nil
    }

    /// Discard the saved clipboard snapshot without pasting (used on reject)
    func cleanup() {
        savedSnapshot = nil
    }

    // MARK: - AX-Based Capture (PID-targeted)

    /// Get selected text directly from the app with the given PID.
    /// This bypasses the system-wide element which can fail with -25204.
    private func getSelectedTextViaAX(pid: pid_t) -> String? {
        let appElement = AXUIElementCreateApplication(pid)

        // Get the focused UI element within that app
        var focusedElement: CFTypeRef?
        let elemResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard elemResult == .success else {
            debugLog("AX (PID \(pid)): can't get focused element (error \(elemResult.rawValue))")
            return nil
        }

        let element = focusedElement as! AXUIElement

        // Read the selected text
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        guard textResult == .success else {
            debugLog("AX (PID \(pid)): can't get selected text (error \(textResult.rawValue))")
            return nil
        }

        let text = selectedText as? String
        debugLog("AX (PID \(pid)): got selected text: \(text?.prefix(50) ?? "nil")")
        return text
    }

    // MARK: - AX-Based Capture (System-wide fallback)

    private func getSelectedTextViaSystemWide() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedApp: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard appResult == .success else {
            debugLog("AX (system-wide): can't get focused app (error \(appResult.rawValue))")
            return nil
        }

        let appElement = focusedApp as! AXUIElement

        var focusedElement: CFTypeRef?
        let elemResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard elemResult == .success else {
            debugLog("AX (system-wide): can't get focused element (error \(elemResult.rawValue))")
            return nil
        }

        let element = focusedElement as! AXUIElement

        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        guard textResult == .success else {
            debugLog("AX (system-wide): can't get selected text (error \(textResult.rawValue))")
            return nil
        }

        let text = selectedText as? String
        debugLog("AX (system-wide): got selected text: \(text?.prefix(50) ?? "nil")")
        return text
    }

    // MARK: - Clipboard-Based Capture (AppleScript)

    private func captureViaClipboard() async -> String? {
        // 1. Wait for the hotkey modifier keys to be released
        debugLog("Clipboard: waiting for modifiers release")
        await waitForModifiersReleased()
        debugLog("Clipboard: modifiers released")

        // 2. Save the full clipboard
        savedSnapshot = ClipboardSnapshot.capture()
        let previousChangeCount = NSPasteboard.general.changeCount
        debugLog("Clipboard: saved snapshot, changeCount=\(previousChangeCount)")

        // 3. Small delay to ensure source app is ready
        try? await Task.sleep(for: .milliseconds(80))

        // 4. Simulate Cmd+C via AppleScript (most reliable cross-app method)
        debugLog("Clipboard: simulating Cmd+C via AppleScript")
        let appleScriptWorked = performCopyViaAppleScript()
        debugLog("Clipboard: AppleScript returned \(appleScriptWorked)")

        // 5. If AppleScript failed, try CGEvent as last resort
        if !appleScriptWorked {
            debugLog("Clipboard: AppleScript failed, trying CGEvent")
            CGEventHelpers.simulateCopy()
        }

        // 6. Wait for the clipboard to change (adaptive polling)
        let changed = await waitForClipboardChange(previousChangeCount: previousChangeCount)
        debugLog("Clipboard: changed=\(changed), newChangeCount=\(NSPasteboard.general.changeCount)")

        var clipboardChanged = changed

        if !clipboardChanged && appleScriptWorked {
            // AppleScript ran but clipboard didn't change — try CGEvent as last resort
            debugLog("Clipboard: AppleScript didn't change clipboard, trying CGEvent fallback")
            CGEventHelpers.simulateCopy()
            clipboardChanged = await waitForClipboardChange(previousChangeCount: previousChangeCount)
            debugLog("Clipboard: CGEvent fallback changed=\(clipboardChanged)")
        }

        guard clipboardChanged else {
            savedSnapshot?.restore()
            savedSnapshot = nil
            return nil
        }

        // 7. Read the plain text from clipboard
        let text = NSPasteboard.general.string(forType: .string)
        debugLog("Clipboard: got text: \(text?.prefix(50) ?? "nil")")

        // 8. Immediately restore the original clipboard
        savedSnapshot?.restore()

        guard let captured = text, !captured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return captured
    }

    // MARK: - AppleScript Keystroke Simulation

    /// Use AppleScript to send Cmd+C via System Events.
    /// This is more reliable than CGEvent because it goes through the
    /// accessibility framework's own event dispatch.
    @discardableResult
    private func performCopyViaAppleScript() -> Bool {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "c" using command down
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error = error {
            debugLog("AppleScript copy error: \(error)")
            return false
        }
        return true
    }

    /// Use AppleScript to send Cmd+V via System Events.
    private func performPasteViaAppleScript() {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "v" using command down
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error = error {
            debugLog("AppleScript paste error: \(error)")
            // Fall back to CGEvent
            CGEventHelpers.simulatePaste()
        }
    }

    // MARK: - Private Helpers

    private func waitForModifiersReleased() async {
        let deadline = ContinuousClock.now + .milliseconds(800)

        while ContinuousClock.now < deadline {
            let flags = CGEventSource.flagsState(.hidSystemState)
            let relevant = flags.intersection([.maskAlternate, .maskShift, .maskControl])
            if relevant.isEmpty {
                // Extra settle time after release
                try? await Task.sleep(for: .milliseconds(80))
                return
            }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    private func waitForClipboardChange(previousChangeCount: Int) async -> Bool {
        let deadline = ContinuousClock.now + maxClipboardWait

        while ContinuousClock.now < deadline {
            if NSPasteboard.general.changeCount != previousChangeCount {
                return true
            }
            try? await Task.sleep(for: .milliseconds(30))
        }

        return false
    }

    // MARK: - Debug

    private func debugLog(_ msg: String) {
        #if DEBUG
        let line = "[\(Date())] [TextCapture] \(msg)\n"
        let path = "/tmp/rephraser-debug.log"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: path) {
                if let handle = FileHandle(forWritingAtPath: path) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: path, contents: data)
            }
        }
        #endif
    }
}
