import Foundation

// MARK: - Retry Helper

/// Retries an async operation with exponential backoff
func withRetry<T>(
    maxAttempts: Int = 3,
    initialDelay: Duration = .milliseconds(500),
    operation: () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 0..<maxAttempts {
        do {
            return try await operation()
        } catch {
            lastError = error

            // Don't retry non-retryable errors
            if let appError = error as? AppError, !appError.isRetryable {
                throw error
            }

            // Don't delay after the last attempt
            if attempt < maxAttempts - 1 {
                let multiplier = Double(1 << attempt) // 1, 2, 4
                let delay = initialDelay * multiplier
                try? await Task.sleep(for: delay)
            }
        }
    }

    throw lastError ?? AppError.unknownError(underlying: "All retry attempts failed")
}
