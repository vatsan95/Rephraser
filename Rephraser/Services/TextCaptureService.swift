import AppKit
import ApplicationServices

// MARK: - Text Capture Service

/// Handles capturing selected text from any app via AX API or clipboard simulation,
/// and pasting rephrased text back.
@MainActor
final class TextCaptureService {
    private var savedSnapshot: ClipboardSnapshot?

    /// Maximum time to wait for clipboard to change after simulating Cmd+C
    var maxClipboardWait: Duration = .milliseconds(1000)

    /// Capture the currently selected text from the frontmost app.
    /// Strategy: try AX API first (instant, no side effects), fall back to Cmd+C.
    func captureSelectedText() async -> String? {
        debugLog("captureSelectedText called")

        // Strategy 1: Try reading selected text directly via Accessibility API.
        if let axText = getSelectedTextViaAX(), !axText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            debugLog("AX capture succeeded: \(axText.prefix(50))...")
            return axText
        }
        debugLog("AX capture returned nil, falling back to clipboard")

        // Strategy 2: Fall back to clipboard simulation (Cmd+C).
        return await captureViaClipboard()
    }

    /// Paste the rephrased text into the source app.
    func pasteText(_ text: String) async {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        try? await Task.sleep(for: .milliseconds(50))
        CGEventHelpers.simulatePaste()
        try? await Task.sleep(for: .milliseconds(150))

        savedSnapshot?.restore()
        savedSnapshot = nil
    }

    /// Discard the saved clipboard snapshot without pasting (used on reject)
    func cleanup() {
        savedSnapshot = nil
    }

    // MARK: - AX-Based Capture

    private func getSelectedTextViaAX() -> String? {
        let systemWide = AXUIElementCreateSystemWide()

        // Get the focused application
        var focusedApp: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard appResult == .success else {
            debugLog("AX: can't get focused app (error \(appResult.rawValue))")
            return nil
        }

        let appElement = focusedApp as! AXUIElement

        // Get the focused UI element within that app
        var focusedElement: CFTypeRef?
        let elemResult = AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        guard elemResult == .success else {
            debugLog("AX: can't get focused element (error \(elemResult.rawValue))")
            return nil
        }

        let element = focusedElement as! AXUIElement

        // Read the selected text
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selectedText)
        guard textResult == .success else {
            debugLog("AX: can't get selected text (error \(textResult.rawValue))")
            return nil
        }

        let text = selectedText as? String
        debugLog("AX: got selected text: \(text?.prefix(50) ?? "nil")")
        return text
    }

    // MARK: - Clipboard-Based Capture

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
        try? await Task.sleep(for: .milliseconds(50))

        // 4. Simulate Cmd+C to copy the selected text
        debugLog("Clipboard: simulating Cmd+C")
        CGEventHelpers.simulateCopy()

        // 5. Wait for the clipboard to change (adaptive polling)
        let changed = await waitForClipboardChange(previousChangeCount: previousChangeCount)
        debugLog("Clipboard: changed=\(changed), newChangeCount=\(NSPasteboard.general.changeCount)")

        guard changed else {
            savedSnapshot?.restore()
            savedSnapshot = nil
            return nil
        }

        // 6. Read the plain text from clipboard
        let text = NSPasteboard.general.string(forType: .string)
        debugLog("Clipboard: got text: \(text?.prefix(50) ?? "nil")")

        // 7. Immediately restore the original clipboard
        savedSnapshot?.restore()

        guard let captured = text, !captured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return captured
    }

    // MARK: - Private Helpers

    private func waitForModifiersReleased() async {
        let deadline = ContinuousClock.now + .milliseconds(500)

        while ContinuousClock.now < deadline {
            let flags = CGEventSource.flagsState(.hidSystemState)
            let relevant = flags.intersection([.maskAlternate, .maskShift, .maskControl])
            if relevant.isEmpty {
                try? await Task.sleep(for: .milliseconds(50))
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
            try? await Task.sleep(for: .milliseconds(20))
        }

        return false
    }

    // MARK: - Debug

    private func debugLog(_ msg: String) {
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
    }
}
