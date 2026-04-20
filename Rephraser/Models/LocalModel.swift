import Foundation

// MARK: - Local Model

struct LocalModel: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let huggingFaceID: String
    let sizeDescription: String
    let parameterCount: String
    let description: String
    var isRecommended: Bool = false
}

// MARK: - Model Catalog

enum ModelCatalog {
    static let all: [LocalModel] = [
        LocalModel(
            id: "phi-4-mini-4bit",
            name: "Phi-4 Mini",
            huggingFaceID: "mlx-community/phi-4-mini-instruct-4bit",
            sizeDescription: "~2.3 GB",
            parameterCount: "3.8B",
            description: "Microsoft's Phi-4 Mini -- best instruction-following, recommended",
            isRecommended: true
        ),
        LocalModel(
            id: "gemma-3-1b-qat-4bit",
            name: "Gemma 3 1B (Lite)",
            huggingFaceID: "mlx-community/gemma-3-1b-it-qat-4bit",
            sizeDescription: "~0.8 GB",
            parameterCount: "1B",
            description: "Google's Gemma 3 -- smallest download, best for short single-sentence rephrases"
        ),
        LocalModel(
            id: "llama-3.2-3b-4bit",
            name: "Llama 3.2 3B",
            huggingFaceID: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            sizeDescription: "~1.8 GB",
            parameterCount: "3B",
            description: "Meta's Llama 3.2 -- balanced size and quality"
        ),
        LocalModel(
            id: "qwen3-4b-4bit",
            name: "Qwen 3 4B",
            huggingFaceID: "mlx-community/Qwen3-4B-4bit",
            sizeDescription: "~2.5 GB",
            parameterCount: "4B",
            description: "Alibaba's Qwen 3 -- strong multilingual support"
        ),
    ]

    static var recommended: LocalModel {
        all.first(where: { $0.isRecommended }) ?? all[0]
    }
}
