import SwiftUI

// MARK: - Streaming Text View

/// Displays text that's being streamed in, with a blinking cursor at the end.
struct StreamingTextView: View {
    let text: String
    let isStreaming: Bool

    @State private var cursorVisible = true

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(text.isEmpty && isStreaming ? " " : text)
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
