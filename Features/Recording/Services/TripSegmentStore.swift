import Foundation
import CoreLocation
import Combine

final class TripSegmentStore {
    static let shared = TripSegmentStore()
    
    let tripTotalsUpdated = PassthroughSubject<Void, Never>()
    
    private let fileManager = FileManager.default
    private let directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let unsortedTripCountKey = "unsortedTripCount"
    
    init() {
        refreshAllTotals()
    }
    
    /// Recompute and persist totals for all supported trip types, then emit `tripTotalsUpdated` once.
    func refreshAllTotals() {
        let types = TripType.allCases
        
        struct Agg { var d: CLLocationDistance = 0; var t: TimeInterval = 0; var c: Int = 0 }
        var results: [(TripType, Agg)] = []
        results.reserveCapacity(types.count)
        let lock = NSLock()
        let group = DispatchGroup()
        
        for type in types {
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                defer { group.leave() }
                guard let self else { return }
                
                let segments = self.loadAll(for: type)
                var agg = Agg()
                for seg in segments {
                    agg.d += seg.distance
                    agg.t += seg.duration
                    agg.c += 1
                }
                
                lock.lock()
                results.append((type, agg))
                lock.unlock()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            for (type, agg) in results {
                var totals = TripTotalsStore(tripType: type)
                totals.totalDistance = agg.d
                totals.totalDuration = agg.t
                totals.tripCount = agg.c
                print("TripTotals for '\(type.name)': totalDistance=\(agg.d), totalDuration=\(agg.t), tripCount=\(agg.c)")
            }
            self.tripTotalsUpdated.send()
        }
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
                DispatchQueue.main.async {
                    TripSegmentStore.shared.refreshAllTotals()
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
                DispatchQueue.main.async {
                    TripSegmentStore.shared.refreshAllTotals()
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
        let unclassifiedTripType = TripType.unclassified
        return loadAll(for: unclassifiedTripType)
    }
    
    func loadAllPersonal() -> [TripSegment] {
        let personalTripType = TripType.personal
        return loadAll(for: personalTripType)
    }
    
    func loadAllBusiness() -> [TripSegment] {
        let businessTripType = TripType.business
        return loadAll(for: businessTripType)
    }
    
    func loadAllCustom() -> [TripSegment] {
        let customTripType = TripType.custom
        return loadAll(for: customTripType)
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
