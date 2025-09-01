import Foundation
import CoreLocation

final class TripStoreSQLite {

    struct Codecs {
        var encodeDisplay: (_ points: [CLLocationCoordinate2D]) throws -> Data
        var decodeDisplay: (_ bytes: Data, _ codec: String, _ version: Int) throws -> [CLLocationCoordinate2D]
        var codecName: String = "lzfse"
        var encodingVersion: Int = 1
    }

    private let codecs: Codecs

    init(codecs: Codecs) {
        self.codecs = codecs
    }

    @discardableResult
    func save(id: String,
              type: TripType,
              start: Date,
              end: Date,
              distanceMeters: Double,
              durationSeconds: Double,
              rawPoints: [LocationPoint]
    ) throws -> TripMeta {
        let pointBytes = try codecs.encodeDisplay(rawPoints.map(\.coordinate))
        let bbox = Self.computeBBox(from: rawPoints.map(\.coordinate))

        let meta = TripMeta(
            id: id,
            type: type.dbValue,
            startTs: Self.epochMillis(start),
            endTs: Self.epochMillis(end),
            distanceM: distanceMeters,
            durationS: durationSeconds,
            bboxMinLat: bbox.minLat,
            bboxMinLon: bbox.minLon,
            bboxMaxLat: bbox.maxLat,
            bboxMaxLon: bbox.maxLon,
            sizeBytes: 0,
            version: 1
        )
        try TripsDAO.insertOrReplace(meta)

        try TripBlobsDAO.writeCompressedBlob(
            tripID: id,
            kind: .display,
            encodingVersion: codecs.encodingVersion,
            rawBytes: pointBytes,
            preferredCodec: .lzfse
        )
        return try TripsDAO.fetch(by: id) ?? meta
    }

    @discardableResult
    func update(id: String,
                type: TripType,
                start: Date,
                end: Date,
                distanceMeters: Double,
                durationSeconds: Double,
                rawPoints: [LocationPoint]) throws -> TripMeta {
        let pointBytes = try codecs.encodeDisplay(rawPoints.map(\.coordinate))
        let bbox = Self.computeBBox(from: rawPoints.map(\.coordinate))

        let meta = TripMeta(
            id: id,
            type: type.dbValue,
            startTs: Self.epochMillis(start),
            endTs: Self.epochMillis(end),
            distanceM: distanceMeters,
            durationS: durationSeconds,
            bboxMinLat: bbox.minLat,
            bboxMinLon: bbox.minLon,
            bboxMaxLat: bbox.maxLat,
            bboxMaxLon: bbox.maxLon,
            sizeBytes: 0,
            version: 1
        )

        try TripsDAO.update(meta)

        try TripBlobsDAO.writeCompressedBlob(
            tripID: id,
            kind: .display,
            encodingVersion: codecs.encodingVersion,
            rawBytes: pointBytes,
            preferredCodec: .lzfse
        )
        return try TripsDAO.fetch(by: id) ?? meta
    }

    func delete(id: String) throws {
        try TripsDAO.delete(id: id)
    }

    func reclassify(id: String, to newType: TripType) throws {
        try TripsDAO.reclassify(id: id, to: newType.dbValue)
    }

    func fetchBreakdownData(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawBreakdownData {
        try TripsDAO.fetchBreakdownData(for: type, from: from, to: to)
    }

    func fetchDOWMeters(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawDOWData {
        try TripsDAO.fetchDOWMeters(for: type, from: from, to: to)
    }
    
    func fetchStartHourHistogram(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawHourData {
        try TripsDAO.fetchStartHourHistogram(for: type, from: from, to: to)
    }
    
    func fetchWeeklyInsights(type: TripType, from: Int64? = nil, to: Int64? = nil) throws -> RawWeekInsights {
        try TripsDAO.fetchWeeklyInsights(for: type, from: from, to: to)
    }
    
    func fetchPage(type: TripType, afterTs: Int64? = nil, limit: Int = 50) throws -> [TripMeta] {
        try TripsDAO.fetchPage(type: type.dbValue, afterTs: afterTs, limit: limit)
    }
    
   func fetchTotals(type: TripType) throws -> Totals {
        try TripsDAO.fetchTotals(for: type.dbValue)
    }

    func fetchMeta(id: String) throws -> TripMeta {
        if let meta = try TripsDAO.fetch(by: id) {
            return meta
        }
        struct NotFound: Error {}
        throw NotFound()
    }

    func fetchDisplayPath(id: String) throws -> [CLLocationCoordinate2D] {
        guard let row = try TripBlobsDAO.readDecompressedBlob(tripID: id, kind: .display) else {
            return []
        }
        return try codecs.decodeDisplay(row.bytes, row.codec, row.encodingVersion)
    }
    
    func count(type: TripType) throws -> Int {
        try TripsDAO.count(for: type.dbValue)
    }

    private static func epochMillis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    private static func computeBBox(from coords: [CLLocationCoordinate2D]) -> (minLat: Int32, minLon: Int32, maxLat: Int32, maxLon: Int32) {
        guard let first = coords.first else { return (0,0,0,0) }
        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude
        for c in coords.dropFirst() {
            if c.latitude < minLat { minLat = c.latitude }
            if c.latitude > maxLat { maxLat = c.latitude }
            if c.longitude < minLon { minLon = c.longitude }
            if c.longitude > maxLon { maxLon = c.longitude }
        }
        func toMicro(_ deg: CLLocationDegrees) -> Int32 { Int32((deg * 1_000_000.0).rounded()) }
        return (toMicro(minLat), toMicro(minLon), toMicro(maxLat), toMicro(maxLon))
    }
}
