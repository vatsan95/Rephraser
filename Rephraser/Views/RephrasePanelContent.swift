import SwiftUI

// MARK: - Rephrase Panel Content

/// The SwiftUI content inside the floating rephrase panel.
struct RephrasePanelContent: View {
    var coordinator: RephraseCoordinator

    @State private var selectedMode: RephraseMode = .professional
    @State private var showDiff = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Content area
            Group {
                switch coordinator.state {
                case .capturing:
                    capturingView
                case .rephrasing, .showingResult:
                    if showDiff && !coordinator.originalText.isEmpty && !coordinator.streamingText.isEmpty {
                        diffView
                    } else {
                        resultView
                    }
                case .showingError:
                    errorView
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer with actions
            footerView
        }
        .background(.ultraThickMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .onAppear {
            selectedMode = coordinator.activeMode
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "text.quote")
                .foregroundStyle(.secondary)

            Text("Rephraser")
                .font(.headline)
                .foregroundStyle(.primary)

            Spacer()

            // Mode picker (only when showing result or rephrasing)
            if coordinator.state == .rephrasing || coordinator.state == .showingResult {
                Picker("", selection: $selectedMode) {
                    ForEach(coordinator.appState.allAvailableModes, id: \.id) { mode in
                        Label(mode.displayName, systemImage: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 160)
                .onChange(of: selectedMode) { _, newMode in
                    if newMode != coordinator.activeMode {
                        coordinator.changeMode(newMode)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Content Views

    private var capturingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Capturing text...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var resultView: some View {
        ScrollView {
            StreamingTextView(
                text: coordinator.streamingText,
                isStreaming: coordinator.isStreaming
            )
            .padding(16)
        }
    }

    private var diffView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Original
                VStack(alignment: .leading, spacing: 4) {
                    Text("ORIGINAL")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(coordinator.originalText)
                        .font(.system(size: 13))
                        .lineSpacing(3)
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.red.opacity(0.15), lineWidth: 1)
                        )
                }

                // Arrow
                Image(systemName: "arrow.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)

                // Rephrased
                VStack(alignment: .leading, spacing: 4) {
                    Text("REPHRASED")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    Text(coordinator.streamingText)
                        .font(.system(size: 13))
                        .lineSpacing(3)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.green.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.green.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            .padding(16)
        }
    }

    private var errorView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text(coordinator.currentError?.title ?? "Error")
                .font(.headline)

            Text(coordinator.currentError?.message ?? "An unknown error occurred.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            if coordinator.state == .showingResult || coordinator.state == .rephrasing {
                // Diff toggle
                Button {
                    showDiff.toggle()
                } label: {
                    Image(systemName: showDiff ? "doc.text" : "arrow.left.arrow.right")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help(showDiff ? "Show result" : "Show changes")

                Text("Enter to accept  ·  Esc to cancel")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else if coordinator.state != .showingError {
                Text("Enter to accept  ·  Esc to cancel")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if coordinator.state == .showingError {
                if let action = coordinator.currentError?.actionLabel {
                    Button(action) {
                        coordinator.handleErrorAction()
                        RephrasePanel.shared.dismissPanel()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                Button("Dismiss") {
                    coordinator.dismissError()
                    RephrasePanel.shared.dismissPanel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .controlSize(.small)
            } else {
                Button("Reject") {
                    coordinator.rejectResult()
                    RephrasePanel.shared.dismissPanel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .controlSize(.small)

                Button("Accept") {
                    acceptAndDismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(coordinator.isStreaming || coordinator.streamingText.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func acceptAndDismiss() {
        // Coordinator handles dismissing panel, refocusing source app, and pasting
        coordinator.acceptResult()
    }
}
