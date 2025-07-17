//
//  MockTripSegmentModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

struct MockTripSegmentModel {
    static func make(
        startTime: Date = Date(),
        endTime: Date = Date(),
        distance: Double = 100,
        startCoordinate: CoordinateModel = CoordinateModel(latitude: 0.0, longitude: 0.0),
        endCoordinate: CoordinateModel = CoordinateModel(latitude: 1.0, longitude: 1.0)
    ) -> TripSegmentModel {
        TripSegmentModel(
            startTime: startTime,
            endTime: endTime,
            startCoordinate: startCoordinate,
            endCoordinate: endCoordinate,
            distance: distance
        )
    }
}
