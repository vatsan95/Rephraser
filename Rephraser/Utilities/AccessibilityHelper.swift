import AppKit
import ApplicationServices

// MARK: - Accessibility Helper

@MainActor
final class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    private var pollingTimer: Timer?

    private init() {}

    /// Check if the app has Accessibility permission
    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Check permission and optionally prompt the user via system dialog
    func checkAccessibility(prompt: Bool = false) -> Bool {
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }
        return AXIsProcessTrusted()
    }

    /// Open System Settings to the Accessibility pane
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Poll for accessibility permission changes, calling the handler when granted
    func startPolling(interval: TimeInterval = 1.0, onGranted: @escaping () -> Void) {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if self?.isAccessibilityGranted == true {
                    self?.stopPolling()
                    onGranted()
                }
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
}
