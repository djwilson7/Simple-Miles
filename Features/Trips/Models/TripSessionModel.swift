//
//  TripSession.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation

struct TripSessionModel: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?

    // Overall metadata
    var distance: Double = 0.0
    var averageSpeed: Double {
        guard let end = endTime else { return 0.0 }
        let duration = end.timeIntervalSince(startTime)
        return duration > 0 ? distance / duration : 0.0
    }

    // Segments of the trip (fine-grained data)
    var segments: [TripSegmentModel] = []
    var tripType: TripType = .unclassified

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        distance: Double = 0.0,
        tripType: TripType = .unclassified,
        segments: [TripSegmentModel] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.distance = distance
        self.tripType = tripType
        self.segments = segments
    }

    mutating func addSegment(_ segment: TripSegmentModel) {
        segments.append(segment)
        distance += segment.distance
    }

    mutating func endSession(at time: Date) {
        self.endTime = time
    }
}
