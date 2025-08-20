//  TripStoreSQLite.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation
import CoreLocation

/// Facade over TripsDAO + TripBlobsDAO.
/// This isolates view models from SQL details and blob encoding.
///
/// Design goals:
/// - App code calls this type; SQL & encoding details live behind it
/// - Supports DB-backed blobs (raw + display)
/// - Can be initialized with custom encoders/decoders so this file compiles
///   before PathEncoder/Decoder are implemented
final class TripStoreSQLite {

    // MARK: - Public API surface

    /// Encoders/Decoders used for blob payloads.
    /// Provide implementations (e.g., PathEncoder/PathDecoder) when wiring.
    struct Codecs {
        /// Return compressed bytes (e.g., LZFSE) for the given path of full LocationPoints
        var encodeRaw: (_ points: [LocationPoint]) throws -> Data
        /// Return compressed bytes for the simplified/path-for-display (coordinates only is fine)
        var encodeDisplay: (_ points: [CLLocationCoordinate2D]) throws -> Data
        /// Decode a compressed DISPLAY blob to coordinates for rendering
        var decodeDisplay: (_ bytes: Data, _ codec: String, _ version: Int) throws -> [CLLocationCoordinate2D]
        /// Decode a compressed RAW blob to full LocationPoints (for export/analysis)
        var decodeRaw: (_ bytes: Data, _ codec: String, _ version: Int) throws -> [LocationPoint]
        /// Codec name to persist in DB (e.g., "lzfse")
        var codecName: String = "lzfse"
        /// Binary layout version (start at 1)
        var encodingVersion: Int = 1
    }

    private let codecs: Codecs

    init(codecs: Codecs) {
        self.codecs = codecs
    }

    // MARK: - Save/Delete/Reclassify

    /// Save a trip with both blobs. If `displayCoordinates` is nil, the caller can pass the same
    /// coordinates derived from the raw points (you may RDP-simplify before calling).
    @discardableResult
    func save(id: String,
              type: TripType,
              start: Date,
              end: Date,
              distanceMeters: Double,
              durationSeconds: Double,
              rawPoints: [LocationPoint],
              displayCoordinates: [CLLocationCoordinate2D]) throws -> TripMeta {
        // Encode blobs
        let rawBytes = try codecs.encodeRaw(rawPoints)
        let displayBytes = try codecs.encodeDisplay(displayCoordinates)

        // Compute bbox from display (good enough for fit; raw would be equivalent)
        let bbox = Self.computeBBox(from: displayCoordinates)

        // Insert/replace metadata row (store TripType as INTEGER via dbValue)
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
            sizeBytes: 0,           // will be updated after blob writes
            version: 1
        )
        try TripsDAO.insertOrReplace(meta)

        // Write blobs (DB-backed)
        try TripBlobsDAO.writeBlob(tripID: id,
                                   kind: .raw,
                                   codec: codecs.codecName,
                                   encodingVersion: codecs.encodingVersion,
                                   bytes: rawBytes)
        try TripBlobsDAO.writeBlob(tripID: id,
                                   kind: .display,
                                   codec: codecs.codecName,
                                   encodingVersion: codecs.encodingVersion,
                                   bytes: displayBytes)

        // Return the final metadata (with updated size)
        return try TripsDAO.fetch(by: id) ?? meta
    }

    /// Delete a trip and its blobs
    func delete(id: String) throws {
        // ON DELETE CASCADE on trip_blobs -> trips requires deleting the parent or the children first.
        // Here we delete the parent row; CASCADE will remove blobs.
        try TripsDAO.delete(id: id)
    }

    /// Reclassify a trip (no file renames, instant totals via SQL)
    func reclassify(id: String, to newType: TripType) throws {
        try TripsDAO.reclassify(id: id, to: newType.dbValue)
    }

    // MARK: - Queries

    /// Fetch a metadata page for a given type, newest first. Keyset pagination via `afterTs`.
    func fetchPage(type: TripType, afterTs: Int64? = nil, limit: Int = 50) throws -> [TripMeta] {
        try TripsDAO.fetchPage(type: type.dbValue, afterTs: afterTs, limit: limit)
    }

    /// Fetch aggregate totals for a type using pure SQL.
    func fetchTotals(type: TripType) throws -> Totals {
        try TripsDAO.fetchTotals(for: type.dbValue)
    }

    /// Load coordinates for the DISPLAY blob (used by map rendering).
    func fetchDisplayPath(id: String) throws -> [CLLocationCoordinate2D] {
        guard let row = try TripBlobsDAO.readBlob(tripID: id, kind: .display) else {
            return []
        }
        return try codecs.decodeDisplay(row.bytes, row.codec, row.encodingVersion)
    }

    /// Load RAW points for export/analysis.
    func fetchRawPoints(id: String) throws -> [LocationPoint] {
        guard let row = try TripBlobsDAO.readBlob(tripID: id, kind: .raw) else {
            return []
        }
        return try codecs.decodeRaw(row.bytes, row.codec, row.encodingVersion)
    }

    // MARK: - Utilities

    private static func epochMillis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    /// Bounding box in microdegrees for quick map fit.
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
