//
//  TripModel.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation

struct TripModel: Identifiable, Codable, Hashable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    var tripType: TripType
    var distance: Double
    var route: [CoordinateModel]
    var averageSpeed: Double?
    var userNotes: String?
    var regionIdentifier: String?

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    var isShortTrip: Bool {
        return duration < 60 || distance < 100
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        tripType: TripType,
        distance: Double,
        route: [CoordinateModel],
        averageSpeed: Double? = nil,
        userNotes: String? = nil,
        regionIdentifier: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.tripType = tripType
        self.distance = distance
        self.route = route
        self.averageSpeed = averageSpeed
        self.userNotes = userNotes
        self.regionIdentifier = regionIdentifier
    }
}
