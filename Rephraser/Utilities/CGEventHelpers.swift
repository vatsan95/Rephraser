import CoreGraphics
import Carbon.HIToolbox

// MARK: - CGEvent Helpers

enum CGEventHelpers {

    /// Simulate Cmd+C (Copy) with proper timing
    static func simulateCopy() {
        simulateKeystroke(keyCode: UInt16(kVK_ANSI_C), modifiers: .maskCommand)
    }

    /// Simulate Cmd+V (Paste) with proper timing
    static func simulatePaste() {
        simulateKeystroke(keyCode: UInt16(kVK_ANSI_V), modifiers: .maskCommand)
    }

    /// Simulate a keystroke with the given key code and modifier flags.
    /// Uses separate key-down and key-up events with a small delay between them
    /// to ensure the target app processes the keystroke reliably.
    private static func simulateKeystroke(keyCode: UInt16, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)

        // Clear any lingering modifier state from the physical keyboard
        // so the simulated event doesn't combine with held keys
        source?.setLocalEventsFilterDuringSuppressionState(
            [.permitLocalMouseEvents, .permitSystemDefinedEvents],
            state: .eventSuppressionStateSuppressionInterval
        )

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }

        keyDown.flags = modifiers
        keyUp.flags = modifiers

        // Post key-down
        keyDown.post(tap: .cgSessionEventTap)

        // Small delay between down and up for reliability
        usleep(30_000) // 30ms

        // Post key-up
        keyUp.post(tap: .cgSessionEventTap)
    }
}
