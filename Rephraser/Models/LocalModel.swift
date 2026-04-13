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
            id: "gemma-3-1b-qat-4bit",
            name: "Gemma 3 1B",
            huggingFaceID: "mlx-community/gemma-3-1b-it-qat-4bit",
            sizeDescription: "~0.8 GB",
            parameterCount: "1B",
            description: "Google's Gemma 3 -- fast download, great for quick rephrasing",
            isRecommended: true
        ),
        LocalModel(
            id: "gemma-3-4b-it-4bit",
            name: "Gemma 3 4B",
            huggingFaceID: "mlx-community/gemma-3-4b-it-4bit",
            sizeDescription: "~2.5 GB",
            parameterCount: "4B",
            description: "Google's Gemma 3 -- best quality for rephrasing"
        ),
        LocalModel(
            id: "qwen3-4b-4bit",
            name: "Qwen 3 4B",
            huggingFaceID: "mlx-community/Qwen3-4B-4bit",
            sizeDescription: "~2.5 GB",
            parameterCount: "4B",
            description: "Alibaba's Qwen 3 -- strong multilingual support"
        ),
        LocalModel(
            id: "phi-4-mini-4bit",
            name: "Phi-4 Mini",
            huggingFaceID: "mlx-community/phi-4-mini-instruct-4bit",
            sizeDescription: "~2.3 GB",
            parameterCount: "3.8B",
            description: "Microsoft's Phi-4 Mini -- compact and efficient"
        ),
        LocalModel(
            id: "llama-3.2-3b-4bit",
            name: "Llama 3.2 3B",
            huggingFaceID: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            sizeDescription: "~1.8 GB",
            parameterCount: "3B",
            description: "Meta's Llama 3.2 -- smallest option, fastest speed"
        ),
    ]

    static var recommended: LocalModel {
        all.first(where: { $0.isRecommended }) ?? all[0]
    }
}
