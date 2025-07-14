//
//  TripSegment.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation

struct TripSegmentModel: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let startCoordinate: CoordinateModel
    let endCoordinate: CoordinateModel
    let distance: Double
    let speed: Double  // meters per second

    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        startCoordinate: CoordinateModel,
        endCoordinate: CoordinateModel,
        distance: Double
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.startCoordinate = startCoordinate
        self.endCoordinate = endCoordinate
        self.distance = distance
        let time = endTime.timeIntervalSince(startTime)
        self.speed = time > 0 ? distance / time : 0.0
    }
}
