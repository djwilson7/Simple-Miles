//
//  MockTripSessionModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
@testable import SimpleMiles

extension TripSessionModel {
    static func mock(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = Date().addingTimeInterval(600),
        distance: Double = 1000,
        tripType: TripType = .business,
        segments: [TripSegmentModel] = [TripSegmentModel.mock()]
    ) -> TripSessionModel {
        TripSessionModel(
            id: id,
            startTime: startTime,
            endTime: endTime,
            distance: distance,
            tripType: tripType,
            segments: segments
        )
    }
}
