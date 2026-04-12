import AppKit

// MARK: - Text Capture Service

/// Handles capturing selected text from any app via clipboard simulation
/// and pasting rephrased text back.
@MainActor
final class TextCaptureService {
    private var savedSnapshot: ClipboardSnapshot?

    /// Maximum time to wait for clipboard to change after simulating Cmd+C
    var maxClipboardWait: Duration = .milliseconds(500)

    /// Capture the currently selected text from the frontmost app.
    /// Saves the full clipboard state, simulates Cmd+C, reads the text,
    /// and immediately restores the original clipboard.
    func captureSelectedText() async -> String? {
        // 1. Save the full clipboard (all types: rich text, images, files, etc.)
        savedSnapshot = ClipboardSnapshot.capture()
        let previousChangeCount = NSPasteboard.general.changeCount

        // 2. Simulate Cmd+C to copy the selected text
        CGEventHelpers.simulateCopy()

        // 3. Wait for the clipboard to change (adaptive polling)
        let changed = await waitForClipboardChange(previousChangeCount: previousChangeCount)

        guard changed else {
            // Clipboard didn't change -- nothing was selected
            savedSnapshot?.restore()
            savedSnapshot = nil
            return nil
        }

        // 4. Read the plain text from clipboard
        let text = NSPasteboard.general.string(forType: .string)

        // 5. Immediately restore the original clipboard
        savedSnapshot?.restore()

        // 6. Return nil if text is empty/whitespace
        guard let captured = text, !captured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return captured
    }

    /// Paste the rephrased text into the source app.
    /// Writes text to clipboard, simulates Cmd+V, then restores original clipboard.
    func pasteText(_ text: String) async {
        // 1. Write rephrased text to clipboard
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        // 2. Brief delay to ensure app is ready to receive paste
        try? await Task.sleep(for: .milliseconds(50))

        // 3. Simulate Cmd+V to paste
        CGEventHelpers.simulatePaste()

        // 4. Wait for paste to complete
        try? await Task.sleep(for: .milliseconds(200))

        // 5. Restore the original clipboard
        savedSnapshot?.restore()
        savedSnapshot = nil
    }

    /// Discard the saved clipboard snapshot without pasting (used on reject)
    func cleanup() {
        savedSnapshot = nil
    }

    // MARK: - Private

    /// Poll the clipboard change count to detect when Cmd+C actually completes.
    /// This handles both fast native apps (~10ms) and slow Electron apps (~300ms).
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
}
