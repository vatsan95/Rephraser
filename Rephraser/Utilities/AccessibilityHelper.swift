import AppKit
import ApplicationServices

// MARK: - Accessibility Helper

@MainActor
final class AccessibilityHelper {
    static let shared = AccessibilityHelper()

    private var pollingTimer: Timer?

    /// Once we detect permission is granted (by a REAL test), we cache it.
    private var cachedGranted = false

    private init() {
        cachedGranted = performRealAccessibilityTest()
    }

    /// Check if the app has Accessibility permission.
    var isAccessibilityGranted: Bool {
        if cachedGranted { return true }
        let result = performRealAccessibilityTest()
        if result { cachedGranted = true }
        return result
    }

    /// Force a fresh check, bypassing the cache
    func recheckPermission() -> Bool {
        let result = performRealAccessibilityTest()
        if result { cachedGranted = true }
        return result
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
    func startPolling(interval: TimeInterval = 1.0, onGranted: @escaping () -> Void) {
        stopPolling()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.performRealAccessibilityTest() {
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

    /// Perform a REAL accessibility test by trying to read from another app.
    /// Previous approach (system-wide query) gave false positives.
    /// This tests against Finder (always running) or any other app to confirm
    /// we truly have cross-app accessibility permission.
    private func performRealAccessibilityTest() -> Bool {
        // First check the API
        if AXIsProcessTrusted() {
            return true
        }

        // API might be stale after user toggled permission.
        // Try a real cross-app AX operation to confirm.
        // Find a running app that isn't us to test against.
        let myPID = ProcessInfo.processInfo.processIdentifier
        let workspace = NSWorkspace.shared

        // Try Finder first (always running)
        if let finder = workspace.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.finder" && $0.processIdentifier != myPID
        }) {
            let appElement = AXUIElementCreateApplication(finder.processIdentifier)
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXRoleAttribute as CFString, &value)
            // -25211 = API disabled (no permission), -25200 = failure
            if result == .success {
                return true
            }
            // If we got apiDisabled, we definitely don't have permission
            if result.rawValue == -25211 {
                return false
            }
        }

        // Try frontmost app
        if let frontApp = workspace.frontmostApplication, frontApp.processIdentifier != myPID {
            let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXRoleAttribute as CFString, &value)
            if result == .success {
                return true
            }
        }

        // Try any running app
        for app in workspace.runningApplications {
            guard app.processIdentifier != myPID,
                  app.activationPolicy == .regular else { continue }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            var value: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appElement, kAXRoleAttribute as CFString, &value)
            if result == .success {
                return true
            }
            // If API disabled, we know for sure
            if result.rawValue == -25211 {
                return false
            }
            break // only try one
        }

        return false
    }
}
