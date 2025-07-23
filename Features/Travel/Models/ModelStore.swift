import Foundation

final class ModelStore {
    static let shared = ModelStore()

    private(set) var modelURL: URL? = nil

    private init() {}

    var isModelAvailable: Bool {
        return modelURL != nil
    }

    func loadModelIfAvailable() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelPath = supportDir.appendingPathComponent("TripStart.mlmodelc")
        if FileManager.default.fileExists(atPath: modelPath.path) {
            modelURL = modelPath
        }
    }

    func updateModelURL(_ url: URL) {
        modelURL = url
    }
}
