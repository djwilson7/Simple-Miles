import Combine
import CoreLocation
import Foundation

final class SegmentStore {
    static let shared = SegmentStore()

    let tripTotalsUpdated = PassthroughSubject<Void, Never>()

    private let store: TripStoreSQLite = {
        let codecs = TripStoreSQLite.Codecs(
            encodeDisplay: { try PathEncoder.encodeDisplay(coords: $0) },
            decodeDisplay: {
                try PathDecoder.decodeDisplay($0, codec: $1, version: $2)
            },
            codecName: "lzfse",
            encodingVersion: 1
        )
        return TripStoreSQLite(codecs: codecs)
    }()

    init() {
        refreshAllTotals()
    }

    func refreshAllTotals() {
        DispatchQueue.main.async { [weak self] in
            self?.tripTotalsUpdated.send()
        }
    }

    func fetchTotals(type: TripType) throws -> Totals {
        try store.fetchTotals(type: type)
    }

    func fetchBreakdownData(
        type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawBreakdownData {
        try store.fetchBreakdownData(type: type, from: from, to: to)
    }

    func fetchDOWMeters(
        type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawDOWData {
        try store.fetchDOWMeters(type: type, from: from, to: to)
    }

    func fetchStartHourHistogram(
        type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawHourData {
        try store.fetchStartHourHistogram(type: type, from: from, to: to)
    }

    func fetchWeeklyInsights(
        type: TripType,
        from: Int64? = nil,
        to: Int64? = nil
    ) throws -> RawWeekInsights {
        try store.fetchWeeklyInsights(type: type, from: from, to: to)
    }

    func write(
        _ segment: TripSegment
    ) {
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
                    rawPoints: segment.pathCoordinates
                )
                DispatchQueue.main.async {
                    self.tripTotalsUpdated.send()
                }
            } catch {
                print(
                    "TripSegmentStore: DB update (by segment.dbID) failed —\(error)"
                )
            }
        }
    }

    func fetchTripIDPage(
        for type: TripType,
        afterTs: Int64? = nil,
        limit: Int = 50
    ) -> [String] {
        let page: [TripMeta] =
            (try? store.fetchPage(type: type, afterTs: afterTs, limit: limit))
            ?? []
        return page.map { $0.id }
    }

    func fetchDisplayPath(for tripID: String) -> [CLLocationCoordinate2D] {
        (try? store.fetchDisplayPath(id: tripID)) ?? []
    }

    func fetchMeta(id: String) throws -> TripMeta {
        try store.fetchMeta(id: id)
    }

    func count(type: TripType) throws -> Int {
        try store.count(type: type)
    }
}
