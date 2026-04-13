import AppKit
import ApplicationServices

// MARK: - Accessibility Helper

@MainActor
final class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    private var pollingTimer: Timer?

    /// Once we detect permission is granted (by any method), we cache it.
    /// This survives the AXIsProcessTrusted() stale-false bug.
    private var cachedGranted = false

    private init() {
        cachedGranted = AXIsProcessTrusted() || testRealAccessibility()
    }

    /// Check if the app has Accessibility permission.
    /// Uses cache + real AX test to work around AXIsProcessTrusted() returning stale false.
    var isAccessibilityGranted: Bool {
        if cachedGranted { return true }
        // Try the API first (fast)
        if AXIsProcessTrusted() {
            cachedGranted = true
            return true
        }
        // API might be stale — do a real AX operation to confirm
        if testRealAccessibility() {
            cachedGranted = true
            return true
        }
        return false
    }

    /// Force a fresh check, bypassing the cache
    func recheckPermission() -> Bool {
        if AXIsProcessTrusted() || testRealAccessibility() {
            cachedGranted = true
            return true
        }
        return false
    }

    /// Check permission and optionally prompt the user via system dialog
    func checkAccessibility(prompt: Bool = false) -> Bool {
        if cachedGranted { return true }
        if prompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            let granted = AXIsProcessTrustedWithOptions(options)
            if granted { cachedGranted = true }
            return granted
        }
        return isAccessibilityGranted
    }

    /// Open System Settings to the Accessibility pane
    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    /// Poll for accessibility permission changes, calling the handler when granted.
    /// Uses a real AX test in addition to AXIsProcessTrusted() to avoid stale results.
    func startPolling(interval: TimeInterval = 1.0, onGranted: @escaping () -> Void) {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                // Try both: the API and a real accessibility operation
                let apiSays = AXIsProcessTrusted()
                let realTest = self.testRealAccessibility()
                if apiSays || realTest {
                    self.cachedGranted = true
                    self.stopPolling()
                    onGranted()
                }
            }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Private

    /// Actually try an AX operation to test if we have permission.
    /// AXIsProcessTrusted() can return false even after the user granted access;
    /// this gives us ground truth.
    private func testRealAccessibility() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &value)
        // If we get .success or .noValue, we have permission.
        // .cannotComplete and .apiDisabled mean no permission.
        return result == .success || result == .noValue
    }
}
