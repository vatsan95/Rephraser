import SwiftUI

// MARK: - Onboarding View

/// Minimal 2-step onboarding: grant accessibility, then done.
/// Model downloads automatically in the background.
struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @Environment(ModelManager.self) private var modelManager

    @State private var currentStep = 0
    @State private var accessibilityGranted = false

    private let totalSteps = 2

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Group {
                switch currentStep {
                case 0: welcomeStep
                case 1: readyStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer()

            // Footer
            footerView
        }
        .frame(width: 480, height: 400)
        .onAppear {
            // Start downloading the recommended model immediately in the background
            if !modelManager.isModelLoaded && !modelManager.isDownloading {
                let recommended = ModelCatalog.recommended
                Task {
                    try? await modelManager.downloadModel(recommended)
                    appState.selectedModelID = recommended.id
                }
            }
        }
    }

    // MARK: - Step 1: Welcome + Accessibility

    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.quote")
                .font(.system(size: 52))
                .foregroundStyle(Color.accentColor)

            Text("Welcome to Rephraser")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Select text in any app, press **⌥⇧R**, and get\na polished version instantly. Free and private.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Accessibility section
            VStack(spacing: 12) {
                Divider()
                    .padding(.horizontal, 60)

                if accessibilityGranted {
                    Label("Accessibility enabled", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    VStack(spacing: 8) {
                        Text("Rephraser needs Accessibility permission to capture and replace text.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)

                        Button("Grant Accessibility Access") {
                            _ = AccessibilityHelper.shared.checkAccessibility(prompt: true)
                            AccessibilityHelper.shared.openAccessibilitySettings()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
            }
            .padding(.top, 4)

            // Background model download indicator
            if modelManager.isDownloading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Downloading AI model (\(Int(modelManager.downloadProgress * 100))%)...")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } else if modelManager.isModelLoaded {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("AI model ready")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
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

    // MARK: - Step 2: Ready

    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(.green)

            Text("You're all set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            VStack(spacing: 16) {
                instructionRow(
                    number: "1",
                    text: "Select any text in any app"
                )
                instructionRow(
                    number: "2",
                    text: "Press  ⌥⇧R"
                )
                instructionRow(
                    number: "3",
                    text: "Press Enter to accept, Esc to cancel"
                )
            }
            .padding(.horizontal, 40)

            if modelManager.isDownloading {
                VStack(spacing: 6) {
                    ProgressView(value: modelManager.downloadProgress)
                        .frame(width: 240)
                    Text("Model downloading... \(Int(modelManager.downloadProgress * 100))% -- you can start using Rephraser once it's done")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }

            Text("Rephraser lives in your menu bar. Right-click the icon to change modes or settings.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Footer

    private var footerView: some View {
        HStack {
            Spacer()

            if currentStep == 0 {
                Button("Continue") {
                    withAnimation { currentStep = 1 }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("Start Rephrasing") {
                    appState.isOnboardingComplete = true
                    AppDelegate.shared?.closeOnboarding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .padding(24)
    }

    // MARK: - Helpers

    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: 14) {
            Text(number)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24, height: 24)
                .background(Color.accentColor.opacity(0.12))
                .clipShape(Circle())

            Text(text)
                .font(.body)

            Spacer()
        }
    }
}
