import Foundation

// MARK: - Preset Rephrase Modes

enum RephraseMode: Identifiable, Hashable, Codable {
    case professional
    case casual
    case concise
    case elaborate
    case fixGrammar
    case custom(CustomMode)

    var id: String {
        switch self {
        case .professional: return "professional"
        case .casual: return "casual"
        case .concise: return "concise"
        case .elaborate: return "elaborate"
        case .fixGrammar: return "fixGrammar"
        case .custom(let mode): return "custom_\(mode.id)"
        }
    }

    var displayName: String {
        switch self {
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .concise: return "Concise"
        case .elaborate: return "Elaborate"
        case .fixGrammar: return "Fix Grammar"
        case .custom(let mode): return mode.name
        }
    }

    var icon: String {
        switch self {
        case .professional: return "briefcase"
        case .casual: return "face.smiling"
        case .concise: return "arrow.down.right.and.arrow.up.left"
        case .elaborate: return "arrow.up.left.and.arrow.down.right"
        case .fixGrammar: return "checkmark.circle"
        case .custom: return "star"
        }
    }

    var systemPrompt: String {
        switch self {
        case .professional:
            return """
            Rephrase the following text to sound professional and polished, suitable for workplace communication.
            Rules:
            - Keep the same meaning and intent
            - Maintain the same language as the input
            - Fix any grammar or spelling errors
            - Use a confident, respectful tone
            - Do not add information not present in the original
            - Return ONLY the rephrased text with no explanation or preamble
            """
        case .casual:
            return """
            Rephrase the following text to sound casual and friendly, like a message to a colleague you're comfortable with.
            Rules:
            - Keep the same meaning and intent
            - Maintain the same language as the input
            - Fix any grammar or spelling errors
            - Use a warm, approachable tone
            - Do not add information not present in the original
            - Return ONLY the rephrased text with no explanation or preamble
            """
        case .concise:
            return """
            Rephrase the following text to be as concise as possible while preserving the full meaning.
            Rules:
            - Remove unnecessary words, filler, and redundancy
            - Keep the same meaning, intent, and tone
            - Maintain the same language as the input
            - Fix any grammar or spelling errors
            - Do not remove important details or nuance
            - Return ONLY the rephrased text with no explanation or preamble
            """
        case .elaborate:
            return """
            Rephrase the following text with more detail and context, making it clearer and more comprehensive.
            Rules:
            - Expand on the ideas naturally without adding false information
            - Keep the same meaning and intent
            - Maintain the same language as the input
            - Fix any grammar or spelling errors
            - Use smooth transitions between ideas
            - Return ONLY the rephrased text with no explanation or preamble
            """
        case .fixGrammar:
            return """
            Fix only the grammar, spelling, and punctuation in the following text. Do NOT change the wording, tone, or style.
            Rules:
            - Correct grammar, spelling, and punctuation errors only
            - Keep the original wording as close as possible
            - Do not rephrase, restructure, or change the tone
            - Maintain the same language as the input
            - Return ONLY the corrected text with no explanation or preamble
            """
        case .custom(let mode):
            return mode.prompt
        }
    }

    static var allPresets: [RephraseMode] {
        [.professional, .casual, .concise, .elaborate, .fixGrammar]
    }
}

// MARK: - Custom Mode

struct CustomMode: Identifiable, Hashable, Codable {
    let id: String
    var name: String
    var prompt: String

    init(name: String, prompt: String) {
        self.id = UUID().uuidString
        self.name = name
        self.prompt = prompt
    }
}
