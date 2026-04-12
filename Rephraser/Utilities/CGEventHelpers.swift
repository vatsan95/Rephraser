import CoreGraphics
import Carbon.HIToolbox

// MARK: - CGEvent Helpers

enum CGEventHelpers {

    /// Simulate Cmd+C (Copy)
    static func simulateCopy() {
        simulateKeystroke(keyCode: UInt16(kVK_ANSI_C), modifiers: .maskCommand)
    }

    /// Simulate Cmd+V (Paste)
    static func simulatePaste() {
        simulateKeystroke(keyCode: UInt16(kVK_ANSI_V), modifiers: .maskCommand)
    }

    /// Simulate a keystroke with the given key code and modifier flags
    private static func simulateKeystroke(keyCode: UInt16, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = modifiers
        keyUp.flags = modifiers

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
