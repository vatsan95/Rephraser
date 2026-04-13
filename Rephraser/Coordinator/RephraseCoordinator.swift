import AppKit

// MARK: - Coordinator State

enum CoordinatorState: Equatable {
    case idle
    case capturing
    case rephrasing
    case showingResult
    case showingError
    case pasting
}

// MARK: - Rephrase Coordinator

/// Orchestrates the full rephrase flow: hotkey -> capture -> AI -> panel -> paste.
/// This is the state machine at the heart of the app.
@Observable
@MainActor
final class RephraseCoordinator {
    // MARK: - State

    private(set) var state: CoordinatorState = .idle
    var streamingText: String = ""
    var isStreaming: Bool = false
    var originalText: String = ""
    var currentError: AppError?
    var activeMode: RephraseMode = .professional

    // MARK: - Dependencies

    let appState: AppState
    let modelManager: ModelManager
    let rephraseService: RephraseService
    let textCapture = TextCaptureService()
    let sourceTracker = SourceAppTracker()
    let hotkeyService = HotkeyService()

    private var currentTask: Task<Void, Never>?

    // MARK: - Constants

    private let maxCharacterCount = 8000

    // MARK: - Init

    init(appState: AppState, modelManager: ModelManager) {
        self.appState = appState
        self.modelManager = modelManager
        self.rephraseService = RephraseService(modelManager: modelManager)
        self.activeMode = appState.defaultMode
    }

    // MARK: - Setup

    func setup() {
        hotkeyService.register { [weak self] in
            self?.triggerRephrase()
        }
        // Apply the saved shortcut from AppState
        hotkeyService.applyShortcut(
            keyCode: appState.shortcutKeyCode,
            modifiers: appState.shortcutModifiers
        )
    }

    /// Update the global shortcut and persist it
    func updateShortcut(keyCode: UInt32, modifiers: UInt32) {
        appState.shortcutKeyCode = keyCode
        appState.shortcutModifiers = modifiers
        hotkeyService.applyShortcut(keyCode: keyCode, modifiers: modifiers)
    }

    // MARK: - Main Flow

    private func debugLog(_ msg: String) {
        let line = "[\(Date())] [Coordinator] \(msg)\n"
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

    /// Triggered by the global hotkey. Starts the full rephrase flow.
    func triggerRephrase() {
        debugLog("triggerRephrase called, state=\(state), modelLoaded=\(modelManager.isModelLoaded), accessibility=\(AccessibilityHelper.shared.isAccessibilityGranted)")

        // Don't trigger if already in a flow
        guard state == .idle else {
            debugLog("BLOCKED: state is \(state), not idle")
            return
        }

        // Check preconditions (show panel with error if failed)
        guard AccessibilityHelper.shared.isAccessibilityGranted else {
            // Trigger the system accessibility prompt dialog
            AccessibilityHelper.shared.checkAccessibility(prompt: true)
            // Also open System Settings directly for the user
            AccessibilityHelper.shared.openAccessibilitySettings()
            // Start polling so we auto-recover when the user grants permission
            AccessibilityHelper.shared.startPolling { [weak self] in
                self?.currentError = nil
                self?.resetToIdle()
                RephrasePanel.shared.dismissPanel()
            }
            showErrorWithPanel(.accessibilityNotGranted)
            return
        }

        guard modelManager.isModelLoaded else {
            showErrorWithPanel(.noModelLoaded)
            return
        }

        // Reset state
        streamingText = ""
        originalText = ""
        isStreaming = false
        currentError = nil

        // Record the source app BEFORE we do anything else.
        // The source app must remain focused during text capture.
        sourceTracker.recordFrontmostApp()

        // Context-aware mode: suggest based on source app, fall back to user's default
        if let suggested = sourceTracker.suggestedMode() {
            activeMode = suggested
        } else {
            activeMode = appState.defaultMode
        }

        // Start the capture flow. Panel is NOT shown yet --
        // Cmd+C must fire while the source app still has focus.
        state = .capturing

        currentTask = Task {
            await performCapture()
        }
    }

    /// Accept the rephrased result and paste it back
    func acceptResult() {
        guard state == .showingResult, !streamingText.isEmpty else { return }
        state = .pasting

        currentTask = Task {
            await performPaste()
        }
    }

    /// Reject the result -- dismiss and go back to idle
    func rejectResult() {
        cancelCurrentTask()
        textCapture.cleanup()
        sourceTracker.clear()
        resetToIdle()
    }

    /// Re-rephrase with a different mode (from the panel dropdown)
    func changeMode(_ mode: RephraseMode) {
        guard state == .showingResult || state == .rephrasing else { return }

        activeMode = mode
        cancelCurrentTask()

        // Re-rephrase with new mode using the same original text
        streamingText = ""
        isStreaming = true
        state = .rephrasing

        currentTask = Task {
            await performRephrase(text: originalText)
        }
    }

    /// Handle the action button on error states
    func handleErrorAction() {
        guard let error = currentError else { return }

        switch error {
        case .accessibilityNotGranted:
            AccessibilityHelper.shared.openAccessibilitySettings()
        case .noModelLoaded:
            AppDelegate.shared?.openSettings()
            resetToIdle()
            return
        case .inferenceFailed, .streamingFailed, .unknownError:
            // Retry: dismiss error, refocus source app, and re-trigger
            let savedOriginalText = originalText
            resetToIdle()
            if !savedOriginalText.isEmpty {
                // We already have the text, just re-rephrase
                originalText = savedOriginalText
                streamingText = ""
                isStreaming = true
                state = .rephrasing
                showPanel()
                currentTask = Task {
                    await performRephrase(text: savedOriginalText)
                }
            }
            return
        default:
            break
        }

        resetToIdle()
    }

    /// Dismiss error and return to idle
    func dismissError() {
        resetToIdle()
    }

    // MARK: - Private Flow Steps

    private func performCapture() async {
        // Pass the source app's PID for direct AX queries
        let sourceAppPID = sourceTracker.sourceAppPID
        debugLog("performCapture: sourceApp=\(sourceTracker.sourceAppName ?? "nil"), pid=\(sourceAppPID.map(String.init) ?? "nil")")

        guard let text = await textCapture.captureSelectedText(sourceAppPID: sourceAppPID) else {
            showErrorWithPanel(.emptySelection)
            return
        }

        // Check text length
        if text.count > maxCharacterCount {
            showErrorWithPanel(.textTooLong(charCount: text.count, maxCount: maxCharacterCount))
            return
        }

        // Text captured successfully. NOW show the panel.
        // From this point, the source app loses focus (panel activates our app),
        // but that's fine -- we already have the text.
        originalText = text
        streamingText = ""
        isStreaming = true
        state = .rephrasing

        showPanel()

        await performRephrase(text: text)
    }

    private func performRephrase(text: String) async {
        do {
            let stream = rephraseService.rephrase(text: text, mode: activeMode)

            try await withThrowingTaskGroup(of: Void.self) { group in
                // Inference task
                group.addTask { @MainActor in
                    for try await chunk in stream {
                        guard !Task.isCancelled else { return }
                        self.streamingText += chunk
                    }
                }

                // Timeout task (30 seconds)
                group.addTask {
                    try await Task.sleep(for: .seconds(30))
                    throw AppError.inferenceFailed(underlying: "Rephrase timed out after 30 seconds. Try again or use a smaller model.")
                }

                // Wait for the first to finish, cancel the other
                try await group.next()
                group.cancelAll()
            }

            guard !Task.isCancelled else { return }
            isStreaming = false
            state = .showingResult

        } catch is CancellationError {
            return
        } catch let error as AppError {
            guard !Task.isCancelled else { return }
            showError(error)
        } catch {
            guard !Task.isCancelled else { return }
            showError(.streamingFailed(underlying: error.localizedDescription))
        }
    }

    private func performPaste() async {
        // Dismiss the panel first
        RephrasePanel.shared.dismissPanel()

        // Brief delay for panel dismissal
        try? await Task.sleep(for: .milliseconds(50))

        // Re-focus the source app (e.g., Slack) so paste goes to the right place
        sourceTracker.refocusSourceApp()

        // Wait for the source app to regain focus
        try? await Task.sleep(for: .milliseconds(80))

        // Paste the rephrased text (writes to clipboard, simulates Cmd+V, restores clipboard)
        await textCapture.pasteText(streamingText)

        // Play completion sound if enabled
        if appState.soundEnabled {
            NSSound(named: .init("Funk"))?.play()
        }

        // Clean up
        sourceTracker.clear()
        resetToIdle()
    }

    // MARK: - Panel Management

    private func showPanel() {
        RephrasePanel.shared.showPanel(with: self)
    }

    private func showErrorWithPanel(_ error: AppError) {
        currentError = error
        isStreaming = false
        state = .showingError
        showPanel()
    }

    // MARK: - Helpers

    private func showError(_ error: AppError) {
        currentError = error
        isStreaming = false
        state = .showingError
    }

    private func resetToIdle() {
        state = .idle
        isStreaming = false
        currentError = nil
    }

    private func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let openSettings = Notification.Name("com.rephraser.openSettings")
}
