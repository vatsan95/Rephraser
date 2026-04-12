import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(ModelManager.self) private var modelManager

    @State private var currentStep = 0
    @State private var selectedModelID: String = ModelCatalog.recommended.id
    @State private var accessibilityGranted = false
    @State private var downloadError: String?

    private let totalSteps = 4

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 24)

            Spacer()

            // Step content
            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: accessibilityStep
                case 2: modelStep
                case 3: modeStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .controlSize(.large)
                }

                Spacer()

                if currentStep < totalSteps - 1 {
                    Button("Continue") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!canContinue)
                } else {
                    Button("Get Started") {
                        appState.isOnboardingComplete = true
                        AppDelegate.shared?.closeOnboarding()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(24)
        }
        .frame(width: 520, height: 480)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.quote")
                .font(.system(size: 56))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Rephraser")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Rephrase text in any app with a single keyboard shortcut.\nSelect text, press ⌥⇧R, and get a polished version instantly.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 16) {
                Label("On-device AI", systemImage: "cpu")
                Label("Private", systemImage: "lock.shield")
                Label("Free", systemImage: "gift")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var accessibilityStep: some View {
        VStack(spacing: 16) {
            Image(systemName: accessibilityGranted ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                .font(.system(size: 48))
                .foregroundStyle(accessibilityGranted ? .green : .orange)

            Text("Accessibility Permission")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Rephraser needs Accessibility access to capture selected text and paste the rephrased version back. This is required for the app to work.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if accessibilityGranted {
                Label("Permission granted!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button("Open System Settings") {
                    _ = AccessibilityHelper.shared.checkAccessibility(prompt: true)
                    AccessibilityHelper.shared.openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)

                Text("After enabling, this screen will update automatically.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .onAppear {
            accessibilityGranted = AccessibilityHelper.shared.isAccessibilityGranted
            if !accessibilityGranted {
                AccessibilityHelper.shared.startPolling {
                    accessibilityGranted = true
                }
            }
        }
        .onDisappear {
            AccessibilityHelper.shared.stopPolling()
        }
    }

    private var modelStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Download a Model")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Rephraser runs AI entirely on your Mac. Choose a model to download -- it stays on your device and works offline.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Model picker
            VStack(spacing: 4) {
                ForEach(ModelCatalog.all) { model in
                    Button {
                        selectedModelID = model.id
                    } label: {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(model.name)
                                        .fontWeight(.medium)
                                    if model.isRecommended {
                                        Text("Recommended")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Color.accentColor)
                                            .clipShape(Capsule())
                                    }
                                }
                                Text("\(model.parameterCount) -- \(model.sizeDescription)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if model.id == selectedModelID {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(model.id == selectedModelID ? Color.accentColor.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 360)

            // Download button / progress
            if modelManager.isDownloading {
                VStack(spacing: 6) {
                    ProgressView(value: modelManager.downloadProgress)
                        .frame(width: 300)
                    Text("Downloading... \(Int(modelManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if modelManager.isModelLoaded {
                Label("Model ready!", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            } else {
                Button("Download Model") {
                    guard let model = ModelCatalog.all.first(where: { $0.id == selectedModelID }) else { return }
                    Task {
                        do {
                            try await modelManager.downloadModel(model)
                            appState.selectedModelID = model.id
                        } catch {
                            downloadError = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let error = downloadError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    private var modeStep: some View {
        VStack(spacing: 16) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            Text("Choose Your Default Mode")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Pick the rephrase style you'll use most often. You can always change this later or switch modes from the result panel.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 4) {
                ForEach(RephraseMode.allPresets, id: \.id) { mode in
                    Button {
                        appState.defaultMode = mode
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: mode.icon)
                                .frame(width: 20)

                            Text(mode.displayName)
                                .fontWeight(.medium)

                            Spacer()

                            if mode.id == appState.defaultMode.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(mode.id == appState.defaultMode.id ? Color.accentColor.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 320)
        }
    }

    // MARK: - Helpers

    private var canContinue: Bool {
        switch currentStep {
        case 0: return true
        case 1: return true // Allow continuing even without accessibility (they can grant later)
        case 2: return true // Allow continuing without model (they can download later)
        case 3: return true
        default: return true
        }
    }
}
