//
//  MockTripSessionModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

struct MockTripSessionModel {
    static func make(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        distance: Double = 100,
        tripType: TripType = .personal,
        segments: [TripSegmentModel] = []
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
