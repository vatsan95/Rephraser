import SwiftUI

// MARK: - Menu Bar View

/// The popover content shown when clicking the menu bar icon.
struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(RephraseCoordinator.self) private var coordinator
    @Environment(ModelManager.self) private var modelManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App title + status
            headerSection

            Divider()
                .padding(.vertical, 4)

            // Download progress (if downloading)
            if modelManager.isDownloading {
                downloadSection

                Divider()
                    .padding(.vertical, 4)
            }

            // Quick mode switcher
            modeSection

            Divider()
                .padding(.vertical, 4)

            // Actions
            actionsSection
        }
        .padding(12)
        .frame(width: 260)
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rephraser")
                    .font(.headline)

                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(coordinator.hotkeyService.currentShortcutDisplay)
                .font(.system(.caption, design: .rounded))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }

    private var downloadSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Downloading AI model...")
                .font(.caption)
                .foregroundStyle(.secondary)

            ProgressView(value: modelManager.downloadProgress)

            Text("\(Int(modelManager.downloadProgress * 100))% complete")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("REPHRASE MODE")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fontWeight(.semibold)

            ForEach(appState.allAvailableModes, id: \.id) { mode in
                Button {
                    appState.defaultMode = mode
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .frame(width: 16)
                            .foregroundStyle(mode.id == appState.defaultMode.id ? .white : .secondary)

                        Text(mode.displayName)
                            .foregroundStyle(mode.id == appState.defaultMode.id ? .white : .primary)

                        Spacer()

                        if mode.id == appState.defaultMode.id {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(mode.id == appState.defaultMode.id ? Color.accentColor : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 2) {
            settingsButton

            Divider()
                .padding(.vertical, 4)

            quitButton
        }
    }

    private var settingsButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "gear")
                .foregroundStyle(.secondary)
            Text("Settings...")
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            DispatchQueue.main.async {
                AppDelegate.shared?.openSettings()
            }
        }
    }

    private var quitButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "power")
                .foregroundStyle(.secondary)
            Text("Quit Rephraser")
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .contentShape(Rectangle())
        .onTapGesture {
            NSApplication.shared.terminate(nil)
        }
    }

    // MARK: - Status

    private var statusColor: Color {
        if modelManager.isDownloading {
            return .orange
        }
        if !AccessibilityHelper.shared.isAccessibilityGranted {
            return .orange
        }
        if modelManager.isLoadingModel {
            return .orange
        }
        if !modelManager.isModelLoaded {
            return .orange
        }
        return .green
    }

    private var statusText: String {
        if modelManager.isDownloading {
            return "Downloading model..."
        }
        if !AccessibilityHelper.shared.isAccessibilityGranted {
            return "Accessibility permission needed"
        }
        if modelManager.isLoadingModel {
            return "Loading model..."
        }
        if !modelManager.isModelLoaded {
            return "No model loaded"
        }
        if let model = appState.selectedModel {
            return "Ready -- \(model.name)"
        }
        return "Ready"
    }
}
