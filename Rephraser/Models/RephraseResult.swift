import Foundation

// MARK: - Rephrase Result

struct RephraseResult: Identifiable {
    let id = UUID()
    let originalText: String
    let rephrasedText: String
    let mode: RephraseMode
    let model: String
    let latencyMs: Int
    let timestamp: Date

    init(
        originalText: String,
        rephrasedText: String,
        mode: RephraseMode,
        model: String,
        latencyMs: Int,
        timestamp: Date = Date()
    ) {
        self.originalText = originalText
        self.rephrasedText = rephrasedText
        self.mode = mode
        self.model = model
        self.latencyMs = latencyMs
        self.timestamp = timestamp
    }
}
