import Foundation

// MARK: - App Error

enum AppError: LocalizedError, Identifiable {
    case accessibilityNotGranted
    case noModelLoaded
    case emptySelection
    case textTooLong(charCount: Int, maxCount: Int)
    case inferenceFailed(underlying: String)
    case modelDownloadFailed(underlying: String)
    case insufficientMemory
    case streamingFailed(underlying: String)
    case unknownError(underlying: String)

    var id: String {
        switch self {
        case .accessibilityNotGranted: return "accessibility"
        case .noModelLoaded: return "noModelLoaded"
        case .emptySelection: return "emptySelection"
        case .textTooLong: return "textTooLong"
        case .inferenceFailed: return "inferenceFailed"
        case .modelDownloadFailed: return "modelDownloadFailed"
        case .insufficientMemory: return "insufficientMemory"
        case .streamingFailed: return "streamingFailed"
        case .unknownError: return "unknownError"
        }
    }

    var title: String {
        switch self {
        case .accessibilityNotGranted:
            return "Accessibility Permission Required"
        case .noModelLoaded:
            return "No Model Loaded"
        case .emptySelection:
            return "No Text Detected"
        case .textTooLong:
            return "Selection Too Long"
        case .inferenceFailed:
            return "Rephrasing Failed"
        case .modelDownloadFailed:
            return "Download Failed"
        case .insufficientMemory:
            return "Insufficient Memory"
        case .streamingFailed:
            return "Rephrasing Failed"
        case .unknownError:
            return "Something Went Wrong"
        }
    }

    var errorDescription: String? {
        message
    }

    var message: String {
        switch self {
        case .accessibilityNotGranted:
            return "Rephraser needs Accessibility permission to capture and replace text. Click below to open System Settings."
        case .noModelLoaded:
            return "No AI model is loaded. Open Settings → Model tab → click Download on a model (Gemma 4 E4B recommended)."
        case .emptySelection:
            return "No text was copied. Make sure text is selected in the other app before pressing the shortcut."
        case .textTooLong(let charCount, let maxCount):
            return "Selection too long (\(charCount.formatted()) characters). Select a shorter passage (max \(maxCount.formatted()))."
        case .inferenceFailed(let underlying):
            return "Rephrasing failed: \(underlying)"
        case .modelDownloadFailed(let underlying):
            return "Model download failed: \(underlying)"
        case .insufficientMemory:
            return "Not enough memory to load the model. Close some apps and try again, or switch to a smaller model like Llama 3.2 3B."
        case .streamingFailed(let underlying):
            return "Rephrasing failed: \(underlying)"
        case .unknownError(let underlying):
            return "Something went wrong: \(underlying). Try again, or check Settings if this persists."
        }
    }

    var actionLabel: String? {
        switch self {
        case .accessibilityNotGranted: return "Open System Settings"
        case .noModelLoaded: return "Open Settings"
        case .inferenceFailed, .streamingFailed, .unknownError: return "Retry"
        default: return nil
        }
    }

    var isRetryable: Bool {
        switch self {
        case .inferenceFailed, .streamingFailed, .unknownError:
            return true
        default:
            return false
        }
    }
}
