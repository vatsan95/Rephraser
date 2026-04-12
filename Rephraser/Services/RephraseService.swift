import Foundation
import MLX
import MLXLLM
import MLXLMCommon

// MARK: - Rephrase Service

/// On-device text rephrasing using MLX local models.
@MainActor
final class RephraseService {
    private let modelManager: ModelManager

    init(modelManager: ModelManager) {
        self.modelManager = modelManager
    }

    /// Stream a rephrase of the given text using the specified mode.
    /// Returns an AsyncThrowingStream that yields text chunks as they arrive.
    func rephrase(text: String, mode: RephraseMode) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let manager = self.modelManager

            Task { @Sendable in
                do {
                    guard let container = manager.currentContainer else {
                        continuation.finish(throwing: AppError.noModelLoaded)
                        return
                    }

                    let messages: [[String: String]] = [
                        ["role": "system", "content": mode.systemPrompt],
                        ["role": "user", "content": text]
                    ]

                    try await container.perform { context in
                        let input = try await context.processor.prepare(
                            input: .init(messages: messages)
                        )

                        let params = GenerateParameters(temperature: 0.7)

                        let stream = try MLXLMCommon.generate(
                            input: input,
                            parameters: params,
                            context: context
                        )

                        for await generation in stream {
                            if Task.isCancelled { break }
                            if let chunk = generation.chunk, !chunk.isEmpty {
                                continuation.yield(chunk)
                            }
                        }
                    }

                    continuation.finish()
                } catch is CancellationError {
                    continuation.finish()
                } catch let error as AppError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: AppError.inferenceFailed(
                        underlying: error.localizedDescription
                    ))
                }
            }
        }
    }
}
