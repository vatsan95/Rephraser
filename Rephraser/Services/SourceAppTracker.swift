import AppKit

// MARK: - Source App Tracker

/// Tracks the frontmost application so we can refocus it after showing the rephrase panel.
@MainActor
final class SourceAppTracker {
    private var sourceApp: NSRunningApplication?

    /// Record the currently active (frontmost) application
    func recordFrontmostApp() {
        sourceApp = NSWorkspace.shared.frontmostApplication
    }

    /// Re-activate the recorded source app (bring it to front)
    func refocusSourceApp() {
        guard let app = sourceApp else { return }

        // Activate the source app, bringing it to the foreground
        app.activate()
    }

    /// Get the name of the recorded source app (for display/debugging)
    var sourceAppName: String? {
        sourceApp?.localizedName
    }

    /// Clear the recorded source app
    func clear() {
        sourceApp = nil
    }
}
