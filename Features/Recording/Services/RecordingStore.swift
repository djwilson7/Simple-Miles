import Foundation
import CoreLocation

final class RecordingStore {
    init() {}

    private let fileManager = FileManager.default
    private let directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    func writeTemporarySegment(_ segment: TripSegment) {
        let url = directory.appendingPathComponent("temp_segment.json")
        write(segment, to: url)
    }

    func updateTemporarySegment(_ segment: TripSegment) {
        writeTemporarySegment(segment)
    }

    func finalizeTemporarySegment() {
        let tempURL = directory.appendingPathComponent("temp_segment.json")
        guard let segment = read(from: tempURL) else { return }
        persistFinalizedSegment(segment)
        try? fileManager.removeItem(at: tempURL)
    }

    func persistFinalizedSegment(_ segment: TripSegment) {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM_dd_yyyy_HH_mm_ss"
        let timestamp = formatter.string(from: segment.startTimestamp)
        let filename = "finalized_\(timestamp).json"
        let url = directory.appendingPathComponent(filename)
        write(segment, to: url)
    }

    func loadAllFinalizedSegments() -> [TripSegment] {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        let segmentFiles = files.filter { $0.lastPathComponent.hasPrefix("finalized_") }
        return segmentFiles.compactMap { read(from: $0) }
                           .sorted(by: { $0.startTimestamp > $1.startTimestamp })
    }
    
    func discardTemporarySegment() {
        let tempURL = directory.appendingPathComponent("temp_segment.json")
        do {
            if fileManager.fileExists(atPath: tempURL.path) {
                try fileManager.removeItem(at: tempURL)
                print("RecordingStore: Discarded temporary segment")
            }
        } catch {
            print("RecordingStore: Failed to discard temporary segment - \(error)")
        }
    }

    private func write(_ segment: TripSegment, to url: URL) {
        DispatchQueue.global(qos: .utility).async {
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
}

    
