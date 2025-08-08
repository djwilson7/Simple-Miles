import Foundation
import CoreLocation
import Combine

final class TripSegmentStore {
    static let shared = TripSegmentStore()
    
    let uncommitedTripsUpdated = PassthroughSubject<Void, Never>()
    
    private let fileManager = FileManager.default
    private let directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let unsortedTripCountKey = "unsortedTripCount"
    
    init() {
        refreshTripCount() // Ensure count is correct on startup
    }
    
    // MARK: - Trip Count Management
    
    func refreshTripCount() {
        let count = loadAllUnclassified().count
        UserDefaults.standard.set(count, forKey: unsortedTripCountKey)
        uncommitedTripsUpdated.send()
    }
    
    // MARK: - Persistence
    
    func write(_ segment: TripSegment) {
        let url = directory.appendingPathComponent(segment.fileName + ".json")
        DispatchQueue.global(qos: .utility).async {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(segment)
                try data.write(to: url)
                print("TripSegmentStore: Saved segment to \(url.lastPathComponent)")
                if segment.tripType.urlPrefix == "unclassified_" {
                    DispatchQueue.main.async {
                        TripSegmentStore.shared.refreshTripCount()
                    }
                }
            } catch {
                print("TripSegmentStore: Failed to save segment - \(error)")
            }
        }
    }
    
    func delete(_ segment: TripSegment) {
        let url = directory.appendingPathComponent(segment.fileName + ".json")
        do {
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
                print("TripSegmentStore: Deleted segment file \(url.lastPathComponent)")
                if segment.tripType.urlPrefix == "unclassified_" {
                    DispatchQueue.main.async {
                        TripSegmentStore.shared.refreshTripCount()
                    }
                }
            } else {
                print("TripSegmentStore: File not found for deletion: \(url.lastPathComponent)")
            }
        } catch {
            print("TripSegmentStore: Failed to delete segment file - \(error)")
        }
    }
    
    // MARK: - Loading
    
    func loadAll(for tripType: TripType) -> [TripSegment] {
        guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else { return [] }
        let prefix = tripType.urlPrefix
        let segmentFiles = files.filter { $0.lastPathComponent.hasPrefix(prefix) }
        return segmentFiles.compactMap { read(from: $0) }
            .sorted(by: { $0.startTimestamp > $1.startTimestamp })
    }
    
    func loadAllUnclassified() -> [TripSegment] {
        let unclassifiedTripType = TripType(name: "unclassified")
        return loadAll(for: unclassifiedTripType)
    }
    
    func loadAllPersonal() -> [TripSegment] {
        let personalTripType = TripType(name: "personal")
        return loadAll(for: personalTripType)
    }
    
    func loadAllBusiness() -> [TripSegment] {
        let businessTripType = TripType(name: "business")
        return loadAll(for: businessTripType)
    }
    
    // MARK: - Helpers
    
    private func read(from url: URL) -> TripSegment? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(TripSegment.self, from: data)
        } catch {
            print("TripSegmentStore: Failed to read segment - \(error)")
            return nil
        }
    }
}
