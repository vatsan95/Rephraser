import Foundation
import TelemetryDeck

/// Lightweight wrapper around TelemetryDeck for privacy-respecting analytics.
/// No personal data, no text content — just anonymous usage signals.
@MainActor
enum Analytics {
    private static let appID = "9D29D1D7-0795-4801-9AA6-B8B42CF9D514"
    private static var isInitialized = false

    /// Call once at app launch
    static func initialize() {
        guard !isInitialized else { return }
        let config = TelemetryDeck.Config(appID: appID)
        TelemetryDeck.initialize(config: config)
        isInitialized = true
    }

    /// Send a signal if analytics is enabled
    static func send(_ signalName: String, parameters: [String: String] = [:]) {
        guard UserDefaults.standard.object(forKey: "analyticsEnabled") == nil ||
              UserDefaults.standard.bool(forKey: "analyticsEnabled") else { return }

        var params = parameters
        // Add app context
        params["appVersion"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        TelemetryDeck.signal(signalName, parameters: params)
    }

    // MARK: - Convenience Methods

    static func trackAppLaunch() {
        send("appLaunched", parameters: [
            "osVersion": ProcessInfo.processInfo.operatingSystemVersionString
        ])
    }

    static func trackModelDownloaded(modelName: String) {
        send("modelDownloaded", parameters: ["model": modelName])
    }

    static func trackModelLoaded(modelName: String) {
        send("modelLoaded", parameters: ["model": modelName])
    }

    static func trackRephraseStarted(mode: String) {
        send("rephraseStarted", parameters: ["mode": mode])
    }

    static func trackRephraseCompleted(mode: String) {
        send("rephraseCompleted", parameters: ["mode": mode])
    }

    static func trackRephraseAccepted(mode: String) {
        send("rephraseAccepted", parameters: ["mode": mode])
    }

    static func trackRephraseRejected() {
        send("rephraseRejected")
    }

    static func trackOnboardingCompleted() {
        send("onboardingCompleted")
    }

    static func trackModeChanged(mode: String) {
        send("modeChanged", parameters: ["mode": mode])
    }
}
