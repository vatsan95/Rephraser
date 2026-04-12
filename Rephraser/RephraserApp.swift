import SwiftUI
import Sparkle

// MARK: - App Entry Point

@main
struct RephraserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Menu Bar -- the only SwiftUI scene we need
        MenuBarExtra("Rephraser", systemImage: "text.quote") {
            MenuBarView()
                .environment(appDelegate.appState)
                .environment(appDelegate.coordinator)
                .environment(appDelegate.modelManager)
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    let appState = AppState()
    let modelManager = ModelManager()
    lazy var coordinator = RephraseCoordinator(appState: appState, modelManager: modelManager)

    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    // Sparkle updater
    lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Setup the coordinator (registers hotkey)
        coordinator.setup()

        if appState.isOnboardingComplete {
            // Returning user: auto-load the previously selected model
            if let model = appState.selectedModel, modelManager.isDownloaded(model) {
                Task { try? await modelManager.loadModel(model) }
            } else if !modelManager.isModelLoaded {
                // Model was deleted or missing — auto-download the recommended one
                autoDownloadRecommended()
            }
        } else {
            // First launch: show onboarding (model download starts inside onboarding)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.openOnboarding()
            }
        }
    }

    // MARK: - Auto Download

    private func autoDownloadRecommended() {
        let recommended = ModelCatalog.recommended
        Task {
            try? await modelManager.downloadModel(recommended)
            appState.selectedModelID = recommended.id
        }
    }

    // MARK: - Settings Window

    func openSettings() {
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let settingsView = SettingsView()
            .environment(appState)
            .environment(modelManager)

        let hostingController = NSHostingController(rootView: settingsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Rephraser Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 460))
        window.center()
        window.isReleasedWhenClosed = false

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Onboarding Window

    func openOnboarding() {
        if let window = onboardingWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = OnboardingView()
            .environment(appState)
            .environment(modelManager)

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Welcome to Rephraser"
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.setContentSize(NSSize(width: 480, height: 400))
        window.center()
        window.isReleasedWhenClosed = false

        onboardingWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
}
