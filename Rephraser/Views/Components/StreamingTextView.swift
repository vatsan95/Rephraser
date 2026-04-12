import SwiftUI

// MARK: - Streaming Text View

/// Displays text that's being streamed in, with a blinking cursor at the end.
struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool

    @State private var cursorVisible = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if text.isEmpty && isStreaming {
                // Show "Generating..." while waiting for first token
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Generating...")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 0) {
                    Text(text)
                        .textSelection(.enabled)
                        .font(.system(size: 14))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if isStreaming {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 2, height: 16)
                            .opacity(cursorVisible ? 1 : 0)
                            .padding(.leading, 1)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: text.isEmpty)
        .onAppear {
            startCursorBlink()
        }
        .onChange(of: isStreaming) { _, newValue in
            if newValue {
                startCursorBlink()
            }
        }
    }

    private func startCursorBlink() {
        guard isStreaming else { return }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            cursorVisible.toggle()
        }
    }
}
