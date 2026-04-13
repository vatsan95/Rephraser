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

        debugLog("Launch: onboarding=\(appState.isOnboardingComplete) model=\(appState.selectedModelID) downloaded=\(modelManager.downloadedModelIDs)")

        if appState.isOnboardingComplete {
            if let model = appState.selectedModel, modelManager.isDownloaded(model) {
                debugLog("Loading model: \(model.name)")
                Task {
                    do {
                        try await modelManager.loadModel(model)
                        debugLog("Model loaded OK")
                    } catch {
                        debugLog("Model load FAILED: \(error)")
                        self.autoDownloadRecommended()
                    }
                }
            } else {
                debugLog("No downloaded model found, selected=\(String(describing: appState.selectedModel?.name)), isDownloaded=\(appState.selectedModel.map { modelManager.isDownloaded($0) } ?? false)")
                if !modelManager.isModelLoaded {
                    autoDownloadRecommended()
                }
            }
        } else {
            // First launch: show onboarding (model download starts inside onboarding)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.openOnboarding()
            }
        }
    }

    // MARK: - Debug

    private func debugLog(_ msg: String) {
        let line = "[\(Date())] \(msg)\n"
        let path = "/tmp/rephraser-debug.log"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: path) {
                if let handle = FileHandle(forWritingAtPath: path) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: path, contents: data)
            }
        }
    }

    // MARK: - Auto Download

    private func autoDownloadRecommended() {
        let recommended = ModelCatalog.recommended
        Task {
            do {
                try await modelManager.downloadModel(recommended)
                appState.selectedModelID = recommended.id
            } catch {
                // Download failed — user can retry from Settings
            }
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
