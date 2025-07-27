import Foundation
import CoreLocation

final class RecordingStore {
    init() {}

    private let fileManager = FileManager.default
    private let directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let segmentExtension = "segment.json"

    /// Persist the currently active segment to disk so it can be recovered across state transitions.
    func writeTemporarySegment(_ segment: TripSegment) {
        let url = directory.appendingPathComponent("active_segment.\(segmentExtension)")
        write(segment, to: url)
    }

    /// Update the temporary segment (for clarity, this simply writes the segment).
    func updateTemporarySegment(_ segment: TripSegment) {
        writeTemporarySegment(segment)
    }

    /// Load the currently active temporary segment from disk.
    func loadTemporarySegment() -> TripSegment? {
        let url = directory.appendingPathComponent("active_segment.\(segmentExtension)")
        return read(from: url)
    }

    /// Finalize the temporary segment by persisting and removing the temporary file.
    func finalizeTemporarySegment() {
        let tempURL = directory.appendingPathComponent("active_segment.\(segmentExtension)")
        guard let segment = read(from: tempURL) else { return }
        persistFinalizedSegment(segment)
        try? fileManager.removeItem(at: tempURL)
    }

    func persistFinalizedSegment(_ segment: TripSegment) {
        let filename = "segment_\(segment.id.uuidString).\(segmentExtension)"
        let url = directory.appendingPathComponent(filename)
        write(segment, to: url)
    }

    func loadAllFinalizedSegments() -> [TripSegment] {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        let segmentFiles = files.filter { $0.pathExtension == "segment.json" && !$0.lastPathComponent.hasPrefix("temp_") }

        return segmentFiles.compactMap { read(from: $0) }
    }

    private func write(_ segment: TripSegment, to url: URL) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(segment)
            try data.write(to: url)
            print("RecordingStore: Saved segment to \(url.lastPathComponent)")
        } catch {
            print("RecordingStore: Failed to save segment - \(error)")
        }
    }

    private func read(from url: URL) -> TripSegment? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(TripSegment.self, from: data)
        } catch {
            print("RecordingStore: Failed to read segment - \(error)")
            return nil
        }
    }

    func deleteAllSegments() {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return }
        for url in files where url.pathExtension == "segment.json" {
            try? fileManager.removeItem(at: url)
        }
    }
}
