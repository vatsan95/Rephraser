import SwiftUI
import ServiceManagement
import Sparkle
import HotKey
import Carbon

// MARK: - Settings View

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(ModelManager.self) private var modelManager

    var body: some View {
        TabView {
            GeneralTab(appState: appState)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            ModelTab(appState: appState, modelManager: modelManager)
                .tabItem {
                    Label("Model", systemImage: "cpu")
                }

            ModesTab(appState: appState)
                .tabItem {
                    Label("Modes", systemImage: "text.badge.star")
                }
        }
        .frame(width: 520, height: 460)
    }
}

// MARK: - General Tab

private struct GeneralTab: View {
    @Bindable var appState: AppState
    @State private var isRecording = false
    @State private var recordedDisplay = ""

    var body: some View {
        Form {
            Section("Keyboard Shortcut") {
                HStack {
                    Text("Rephrase shortcut:")
                    Spacer()

                    if isRecording {
                        Text(recordedDisplay.isEmpty ? "Press keys..." : recordedDisplay)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(recordedDisplay.isEmpty ? .secondary : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: 1.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Text(appState.shortcutDisplay)
                            .font(.system(.body, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .onTapGesture { isRecording = true }
                    }

                    if isRecording {
                        Button("Cancel") {
                            isRecording = false
                            recordedDisplay = ""
                        }
                        .controlSize(.small)
                    } else {
                        Button("Change") {
                            isRecording = true
                        }
                        .controlSize(.small)
                    }
                }
                .background(
                    ShortcutRecorderView(
                        isRecording: $isRecording,
                        recordedDisplay: $recordedDisplay,
                        appState: appState
                    )
                    .frame(width: 0, height: 0)
                )

                if appState.shortcutDisplay != "⌥⇧R" {
                    Button("Reset to Default (⌥⇧R)") {
                        let coordinator = AppDelegate.shared?.coordinator
                        let defaultKeyCode = Key.r.carbonKeyCode
                        let defaultModifiers = NSEvent.ModifierFlags([.option, .shift]).carbonFlags
                        coordinator?.updateShortcut(keyCode: defaultKeyCode, modifiers: defaultModifiers)
                    }
                    .controlSize(.small)
                }
            }

            Section("Default Mode") {
                Picker("Default rephrase mode:", selection: $appState.defaultMode) {
                    ForEach(appState.allAvailableModes, id: \.id) { mode in
                        Label(mode.displayName, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
            }

            Section("Behavior") {
                Toggle("Play sound on rephrase", isOn: $appState.soundEnabled)
                Toggle("Launch at login", isOn: $appState.launchAtLogin)
            }

            Section("Analytics") {
                Toggle("Send anonymous usage stats", isOn: $appState.analyticsEnabled)
                Text("No text content is ever sent. Just anonymous event counts to help improve the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Updates") {
                HStack {
                    Text("Rephraser v1.0.0")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Check for Updates") {
                        AppDelegate.shared?.updaterController.updater.checkForUpdates()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Model Tab

private struct ModelTab: View {
    @Bindable var appState: AppState
    var modelManager: ModelManager

    var body: some View {
        Form {
            Section {
                if modelManager.isModelLoaded, let model = appState.selectedModel {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Active: \(model.name)")
                            .fontWeight(.medium)
                        Spacer()
                        Text(model.parameterCount)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                    }
                } else if modelManager.isLoadingModel {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading model...")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundStyle(.orange)
                        Text("No model loaded")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Available Models") {
                ForEach(ModelCatalog.all) { model in
                    ModelRow(
                        model: model,
                        appState: appState,
                        modelManager: modelManager
                    )
                }
            }

            if modelManager.isDownloading {
                Section("Download Progress") {
                    VStack(alignment: .leading, spacing: 6) {
                        ProgressView(value: modelManager.downloadProgress)
                        Text("\(Int(modelManager.downloadProgress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct ModelRow: View {
    let model: LocalModel
    let appState: AppState
    var modelManager: ModelManager

    @State private var errorMessage: String?

    private var isActive: Bool { modelManager.loadedModelID == model.id }
    private var isDownloaded: Bool { modelManager.isDownloaded(model) }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(model.name)
                            .fontWeight(.medium)
                        if model.isRecommended {
                            Text("Recommended")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(model.description) -- \(model.sizeDescription)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .fontWeight(.medium)
                } else if isDownloaded {
                    HStack(spacing: 8) {
                        Button("Load") {
                            errorMessage = nil
                            Task {
                                do {
                                    try await modelManager.loadModel(model)
                                    appState.selectedModelID = model.id
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        }
                        .controlSize(.small)

                        Button(role: .destructive) {
                            modelManager.deleteModel(model)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .controlSize(.small)
                        .buttonStyle(.borderless)
                    }
                } else if modelManager.isDownloading {
                    Text("...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } else {
                    Button("Download") {
                        errorMessage = nil
                        Task {
                            do {
                                try await modelManager.downloadModel(model)
                                appState.selectedModelID = model.id
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .controlSize(.small)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Modes Tab

private struct ModesTab: View {
    @Bindable var appState: AppState
    @State private var newModeName = ""
    @State private var newModePrompt = ""
    @State private var isAddingMode = false

    var body: some View {
        Form {
            Section("Preset Modes") {
                ForEach(RephraseMode.allPresets, id: \.id) { mode in
                    Toggle(isOn: presetToggle(for: mode)) {
                        Label(mode.displayName, systemImage: mode.icon)
                    }
                }
            }

            Section("Custom Modes") {
                ForEach(appState.customModes) { mode in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(mode.name)
                                .font(.subheadline)
                            Text(mode.prompt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Button(role: .destructive) {
                            appState.customModes.removeAll { $0.id == mode.id }
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }

                if isAddingMode {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Mode name", text: $newModeName)
                            .textFieldStyle(.roundedBorder)

                        TextEditor(text: $newModePrompt)
                            .frame(height: 80)
                            .font(.system(.caption, design: .monospaced))
                            .border(Color.secondary.opacity(0.3))

                        HStack {
                            Button("Cancel") {
                                isAddingMode = false
                                newModeName = ""
                                newModePrompt = ""
                            }
                            Button("Add") {
                                let mode = CustomMode(name: newModeName, prompt: newModePrompt)
                                appState.customModes.append(mode)
                                isAddingMode = false
                                newModeName = ""
                                newModePrompt = ""
                            }
                            .disabled(newModeName.isEmpty || newModePrompt.isEmpty)
                        }
                    }
                } else {
                    Button {
                        isAddingMode = true
                    } label: {
                        Label("Add Custom Mode", systemImage: "plus")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func presetToggle(for mode: RephraseMode) -> Binding<Bool> {
        Binding(
            get: { appState.enabledPresetModes.contains(mode.id) },
            set: { enabled in
                if enabled {
                    appState.enabledPresetModes.insert(mode.id)
                } else {
                    appState.enabledPresetModes.remove(mode.id)
                }
            }
        )
    }
}

// MARK: - Shortcut Recorder

/// Invisible NSView that captures key events when recording mode is active.
private struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var recordedDisplay: String
    let appState: AppState

    func makeNSView(context: Context) -> NSView {
        let view = ShortcutCaptureNSView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isRecording = isRecording
        if isRecording {
            context.coordinator.startMonitoring()
        } else {
            context.coordinator.stopMonitoring()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isRecording: $isRecording, recordedDisplay: $recordedDisplay, appState: appState)
    }

    class Coordinator {
        var isRecording = false
        private var monitor: Any?
        private var isRecordingBinding: Binding<Bool>
        private var recordedDisplayBinding: Binding<String>
        private let appState: AppState

        init(isRecording: Binding<Bool>, recordedDisplay: Binding<String>, appState: AppState) {
            self.isRecordingBinding = isRecording
            self.recordedDisplayBinding = recordedDisplay
            self.appState = appState
        }

        func startMonitoring() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self, self.isRecording else { return event }

                let modifiers = event.modifierFlags.intersection([.command, .option, .shift, .control])

                // Escape cancels recording
                if event.keyCode == UInt16(kVK_Escape) {
                    DispatchQueue.main.async {
                        self.isRecordingBinding.wrappedValue = false
                        self.recordedDisplayBinding.wrappedValue = ""
                    }
                    return nil
                }

                // Require at least one modifier key
                guard !modifiers.isEmpty else { return nil }

                // Must have a valid non-modifier key
                guard let key = Key(carbonKeyCode: UInt32(event.keyCode)) else { return nil }
                // Skip if the key itself is a modifier
                let modifierKeys: [Key] = [.command, .shift, .option, .control,
                                            .rightCommand, .rightShift, .rightOption, .rightControl]
                guard !modifierKeys.contains(key) else { return nil }

                let carbonKeyCode = UInt32(event.keyCode)
                let carbonModifiers = modifiers.carbonFlags

                DispatchQueue.main.async {
                    let coordinator = AppDelegate.shared?.coordinator
                    coordinator?.updateShortcut(keyCode: carbonKeyCode, modifiers: carbonModifiers)
                    self.isRecordingBinding.wrappedValue = false
                    self.recordedDisplayBinding.wrappedValue = ""
                }

                return nil // Swallow the event
            }
        }

        func stopMonitoring() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        deinit {
            stopMonitoring()
        }
    }
}

private class ShortcutCaptureNSView: NSView {
    weak var delegate: ShortcutRecorderView.Coordinator?
}
