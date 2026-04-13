import Foundation
import MLX
import MLXLLM
import MLXLMCommon

// MARK: - Model Manager

/// Manages downloading, loading, and lifecycle of on-device LLM models.
@Observable
@MainActor
final class ModelManager {
    // MARK: - State

    private(set) var isModelLoaded = false
    private(set) var loadedModelID: String?
    private(set) var isDownloading = false
    private(set) var downloadProgress: Double = 0
    private(set) var isLoadingModel = false
    private(set) var downloadedModelIDs: Set<String> = []

    private var modelContainer: ModelContainer?

    // MARK: - Storage

    private let downloadedModelsKey = "downloadedModelIDs"

    // MARK: - Init

    init() {
        // Load persisted set of downloaded model IDs
        if let ids = UserDefaults.standard.array(forKey: downloadedModelsKey) as? [String] {
            downloadedModelIDs = Set(ids)
        }

        // Scan the HF cache to detect models that are on disk but not in our persisted set
        // (e.g. after a fresh install with a pre-existing cache, or if UserDefaults was cleared)
        for model in ModelCatalog.all {
            if !downloadedModelIDs.contains(model.id) && isModelCachedOnDisk(model) {
                downloadedModelIDs.insert(model.id)
            }
        }
        persistDownloadedIDs()

        // Set a small GPU cache limit to keep idle memory low
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
    }

    // MARK: - Public API

    /// The currently loaded model container for inference.
    var currentContainer: ModelContainer? { modelContainer }

    /// Check if a specific model is downloaded.
    func isDownloaded(_ model: LocalModel) -> Bool {
        downloadedModelIDs.contains(model.id)
    }

    /// Download a model from Hugging Face. Progress is reported via `downloadProgress`.
    func downloadModel(_ model: LocalModel) async throws {
        guard !isDownloading else { return }

        isDownloading = true
        downloadProgress = 0

        do {
            let config = ModelConfiguration(id: model.huggingFaceID)

            // This downloads (if needed) and loads the model
            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: config
            ) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress.fractionCompleted
                }
            }

            // Mark as downloaded
            downloadedModelIDs.insert(model.id)
            persistDownloadedIDs()

            // Also set it as the loaded model
            modelContainer = container
            loadedModelID = model.id
            isModelLoaded = true

            isDownloading = false
            downloadProgress = 1.0
        } catch {
            isDownloading = false
            downloadProgress = 0
            throw AppError.modelDownloadFailed(underlying: error.localizedDescription)
        }
    }

    /// Load a previously downloaded model into memory.
    func loadModel(_ model: LocalModel) async throws {
        guard !isLoadingModel else { return }

        // Unload current model first
        if isModelLoaded {
            unloadModel()
        }

        isLoadingModel = true
        NSLog("[Rephraser] Loading model: %@ (%@)", model.name, model.huggingFaceID)

        do {
            let config = ModelConfiguration(id: model.huggingFaceID)

            let container = try await LLMModelFactory.shared.loadContainer(
                configuration: config
            ) { progress in
                Task { @MainActor in
                    self.downloadProgress = progress.fractionCompleted
                }
            }

            modelContainer = container
            loadedModelID = model.id
            isModelLoaded = true
            isLoadingModel = false
            NSLog("[Rephraser] Model loaded successfully: %@", model.name)

            // Ensure it's in the downloaded set
            if !downloadedModelIDs.contains(model.id) {
                downloadedModelIDs.insert(model.id)
                persistDownloadedIDs()
            }
        } catch {
            isLoadingModel = false
            NSLog("[Rephraser] Model load FAILED: %@", "\(error)")
            throw AppError.inferenceFailed(underlying: "Failed to load model: \(error.localizedDescription)")
        }
    }

    /// Unload the current model from memory.
    func unloadModel() {
        modelContainer = nil
        loadedModelID = nil
        isModelLoaded = false
        MLX.GPU.clearCache()
    }

    /// Delete a downloaded model from disk.
    func deleteModel(_ model: LocalModel) {
        // Unload if it's the active model
        if loadedModelID == model.id {
            unloadModel()
        }

        // Remove from downloaded set
        downloadedModelIDs.remove(model.id)
        persistDownloadedIDs()

        // Remove cached files from Hugging Face hub cache
        let repoSlug = model.huggingFaceID.replacingOccurrences(of: "/", with: "--")
        let cacheDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/huggingface/hub/models--\(repoSlug)")

        try? FileManager.default.removeItem(at: cacheDir)
    }

    // MARK: - Private

    private func persistDownloadedIDs() {
        UserDefaults.standard.set(Array(downloadedModelIDs), forKey: downloadedModelsKey)
    }

    /// Check if a model's weight files exist in the Hugging Face hub cache.
    private func isModelCachedOnDisk(_ model: LocalModel) -> Bool {
        let repoSlug = model.huggingFaceID.replacingOccurrences(of: "/", with: "--")
        let snapshotsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/huggingface/hub/models--\(repoSlug)/snapshots")

        guard let snapshots = try? FileManager.default.contentsOfDirectory(atPath: snapshotsDir.path),
              let snapshot = snapshots.first(where: { !$0.hasPrefix(".") }) else {
            return false
        }

        // Check that actual model weight files exist (not just config files)
        let snapshotPath = snapshotsDir.appendingPathComponent(snapshot).path
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: snapshotPath) else {
            return false
        }
        return files.contains(where: { $0.hasSuffix(".safetensors") })
    }
}
