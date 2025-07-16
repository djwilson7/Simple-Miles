//
//  TaxTripSchema.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

struct CSVExportSchema {
    let tripID: UUID
    let date: String
    let startTime: String
    let endTime: String
    let startLat: Double
    let startLon: Double
    let endLat: Double
    let endLon: Double
    let tripType: String
    let distanceMeters: Double
    let distanceMiles: Double
    let durationMinutes: Double
    let segmentCount: Int

    init(from model: TripSessionModel) {
        self.tripID = model.id

        let start = model.startTime
        let end = model.endTime ?? start

        self.date = CSVExportSchema.dateFormatter.string(from: start)
        self.startTime = CSVExportSchema.timeFormatter.string(from: start)
        self.endTime = CSVExportSchema.timeFormatter.string(from: end)

        let first = model.segments.first
        let last = model.segments.last

        self.startLat = first?.startCoordinate.latitude ?? 0
        self.startLon = first?.startCoordinate.longitude ?? 0
        self.endLat = last?.endCoordinate.latitude ?? 0
        self.endLon = last?.endCoordinate.longitude ?? 0

        self.tripType = model.tripType.rawValue
        self.distanceMeters = model.distance
        self.distanceMiles = model.distance / 1609.34
        self.durationMinutes = (end.timeIntervalSince(start)) / 60
        self.segmentCount = model.segments.count
    }

    static let headers = [
        "trip_id", "date", "start_time", "end_time",
        "start_lat", "start_lon", "end_lat", "end_lon",
        "trip_type", "distance_meters", "distance_miles",
        "duration_minutes", "segment_count"
    ]

    func toCSVRow() -> String {
        [
            tripID.uuidString,
            date,
            startTime,
            endTime,
            String(format: "%.6f", startLat),
            String(format: "%.6f", startLon),
            String(format: "%.6f", endLat),
            String(format: "%.6f", endLon),
            tripType,
            String(format: "%.2f", distanceMeters),
            String(format: "%.2f", distanceMiles),
            String(format: "%.1f", durationMinutes),
            "\(segmentCount)"
        ].joined(separator: ",")
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
