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

    /// Get the bundle identifier of the recorded source app
    var sourceAppBundleID: String? {
        sourceApp?.bundleIdentifier
    }

    /// Get the PID of the recorded source app (for direct AX queries)
    var sourceAppPID: pid_t? {
        sourceApp?.processIdentifier
    }

    /// Suggest a rephrase mode based on the source app
    func suggestedMode() -> RephraseMode? {
        guard let bundleID = sourceAppBundleID?.lowercased() else { return nil }

        // Casual: messaging and social apps
        if bundleID.contains("slack") || bundleID.contains("discord") ||
           bundleID.contains("telegram") || bundleID.contains("whatsapp") ||
           bundleID.contains("messages") || bundleID.contains("ichat") {
            return .casual
        }

        // Professional: email and docs
        if bundleID.contains("mail") || bundleID.contains("gmail") ||
           bundleID.contains("outlook") || bundleID.contains("notion") ||
           bundleID.contains("pages") || bundleID.contains("word") ||
           bundleID.contains("docs") || bundleID.contains("linkedin") {
            return .professional
        }

        // Fix Grammar: code editors
        if bundleID.contains("xcode") || bundleID.contains("vscode") ||
           bundleID.contains("visual studio") || bundleID.contains("jetbrains") ||
           bundleID.contains("sublime") || bundleID.contains("cursor") ||
           bundleID.contains("textmate") || bundleID.contains("bbedit") {
            return .fixGrammar
        }

        return nil
    }

    /// Clear the recorded source app
    func clear() {
        sourceApp = nil
    }
}
