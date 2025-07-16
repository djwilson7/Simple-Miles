//
//  MockTripSegmentModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
@testable import SimpleMiles

extension TripSegmentModel {
    static func mock(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date = Date().addingTimeInterval(60),
        distance: Double = 100.0,
        startCoordinate: CoordinateModel = CoordinateModel(latitude: 1.0, longitude: 1.0),
        endCoordinate: CoordinateModel = CoordinateModel(latitude: 2.0, longitude: 2.0)
    ) -> TripSegmentModel {
        return TripSegmentModel(
            id: id,
            startTime: startTime,
            endTime: endTime,
            startCoordinate: startCoordinate,
            endCoordinate: endCoordinate,
            distance: distance
        )
    }
}
