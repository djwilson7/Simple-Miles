//
//  TripMeta.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation

/// Lightweight metadata model for a single trip row in the `trips` table.
/// Distances are meters; durations are seconds; timestamps are epoch milliseconds.
public struct TripMeta: Equatable, Codable {
    public let id: String
    public let type: Int
    public let startTs: Int64
    public let endTs: Int64
    public let distanceM: Double
    public let durationS: Double
    public let bboxMinLat: Int32
    public let bboxMinLon: Int32
    public let bboxMaxLat: Int32
    public let bboxMaxLon: Int32
    public let sizeBytes: Int64
    public let version: Int

    public init(id: String,
                type: Int,
                startTs: Int64,
                endTs: Int64,
                distanceM: Double,
                durationS: Double,
                bboxMinLat: Int32,
                bboxMinLon: Int32,
                bboxMaxLat: Int32,
                bboxMaxLon: Int32,
                sizeBytes: Int64,
                version: Int) {
        self.id = id
        self.type = type
        self.startTs = startTs
        self.endTs = endTs
        self.distanceM = distanceM
        self.durationS = durationS
        self.bboxMinLat = bboxMinLat
        self.bboxMinLon = bboxMinLon
        self.bboxMaxLat = bboxMaxLat
        self.bboxMaxLon = bboxMaxLon
        self.sizeBytes = sizeBytes
        self.version = version
    }
}

public extension TripMeta {
    /// Convenience accessors for Dates (derived from epoch milliseconds).
    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(startTs) / 1000.0) }
    var endDate: Date { Date(timeIntervalSince1970: TimeInterval(endTs) / 1000.0) }

    /// Whether this metadata row represents zero-length/empty content.
    var isEmpty: Bool { distanceM <= 0 || durationS <= 0 }
    
    internal var tripType: TripType? {
        TripType(dbValue: type)
    }
}
