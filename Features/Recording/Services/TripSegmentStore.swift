import Foundation
import CoreLocation
import Combine

final class TripSegmentStore {
    static let shared = TripSegmentStore()
    
    let tripTotalsUpdated = PassthroughSubject<Void, Never>()

    // SQLite-backed store facade
    private let store: TripStoreSQLite = {
        let codecs = TripStoreSQLite.Codecs(
            encodeDisplay: { try PathEncoder.encodeDisplay(coords: $0) },
            decodeDisplay: { try PathDecoder.decodeDisplay($0, codec: $1, version: $2) },
            codecName: "lzfse",
            encodingVersion: 1
        )
        return TripStoreSQLite(codecs: codecs)
    }()
    
    init() {
        refreshAllTotals()
    }
    
    /// Recompute and persist totals for all supported trip types, then emit `tripTotalsUpdated` once.
    func refreshAllTotals() {
        // Totals are now pulled on demand by listeners (e.g., SortedTripTotalsModel)
        // Emit a single signal so subscribers can refetch from SQLite.
        DispatchQueue.main.async { [weak self] in
            self?.tripTotalsUpdated.send()
        }
    }
    
    /// Fetch aggregated totals for a given type directly from SQLite.
    func fetchTotals(type: TripType) throws -> Totals {
        try store.fetchTotals(type: type)
    }

    /// Fetch summed distance for a type (and overall totals) within an optional date range.
    /// NOTE: Values are raw meters (DAO keeps raw meters despite the "Miles" naming).
    func fetchBreakdownData(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawBreakdownData {
        try store.fetchBreakdownData(type: type, from: from, to: to)
    }
    
    /// Fetch summed distance for a type (and overall totals) within an optional date range.
    /// NOTE: Values are raw meters (DAO keeps raw meters despite the "Miles" naming).
    func fetchDOWMeters(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawDOWData {
        try store.fetchDOWMeters(type: type, from: from, to: to)
    }

    func fetchStartHourHistogram(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawHourData {
        try store.fetchStartHourHistogram(type: type, from: from, to: to)
    }
    
    // MARK: - Persistence (SQLite)
    
    func write(_ segment: TripSegment) {
        let end = segment.endTimestamp ?? segment.startTimestamp
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            do {
                _ = try self.store.save(
                    id: segment.dbID,
                    type: segment.tripType,
                    start: segment.startTimestamp,
                    end: end,
                    distanceMeters: segment.distance,
                    durationSeconds: segment.duration,
                    rawPoints: segment.pathCoordinates
                )
                DispatchQueue.main.async { self.tripTotalsUpdated.send() }
            } catch {
                print("TripSegmentStore: DB save failed —\(error)")
            }
        }
    }
    
    func delete(_ segment: TripSegment) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            do {
                try self.store.delete(id: segment.dbID)
                DispatchQueue.main.async { self.tripTotalsUpdated.send() }
            } catch {
                print("TripSegmentStore: DB delete failed —\(error)")
            }
        }
    }
    

    /// Reclassify a trip to a new type (DB-backed). Emits `tripTotalsUpdated` on success.
    func reclassify(tripID: String, to newType: TripType) {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            do {
                try self.store.reclassify(id: tripID, to: newType)
                DispatchQueue.main.async { self.tripTotalsUpdated.send() }
            } catch {
                print("TripSegmentStore: DB reclassify failed —\(error)")
            }
        }
    }
    
    /// Update an existing trip row using the segment's own dbID.
    /// Mirrors the reclassify threading pattern: background do, main post.
    func update(_ segment: TripSegment) {
        let end = segment.endTimestamp ?? segment.startTimestamp

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            do {
                try self.store.update(
                    id: segment.dbID,
                    type: segment.tripType,
                    start: segment.startTimestamp,
                    end: end,
                    distanceMeters: segment.distance,
                    durationSeconds: segment.duration,
                    rawPoints: segment.pathCoordinates,
                )
                DispatchQueue.main.async {
                    self.tripTotalsUpdated.send()
                }
            } catch {
                print("TripSegmentStore: DB update (by segment.dbID) failed —\(error)")
            }
        }
    }
    // MARK: - Paging / Loading (SQLite)

    /// Fetch just the trip IDs for a single page (newest first). Cheap: avoids decoding meta.
    func fetchTripIDPage(for type: TripType, afterTs: Int64? = nil, limit: Int = 50) -> [String] {
        let page: [TripMeta] = (try? store.fetchPage(type: type, afterTs: afterTs, limit: limit)) ?? []
        return page.map { $0.id }
    }

    /// Load the DISPLAY polyline for a given trip id (fast, simplified path for map rendering).
    func fetchDisplayPath(for tripID: String) -> [CLLocationCoordinate2D] {
        (try? store.fetchDisplayPath(id: tripID)) ?? []
    }

    /// Load TripMeta for a given trip id (no blobs). Thin façade over SQLite layer.
    func fetchMeta(id: String) throws -> TripMeta {
        try store.fetchMeta(id: id)
    }
    
    func count(type: TripType) throws -> Int {
        try store.count(type: type)
    }
}
