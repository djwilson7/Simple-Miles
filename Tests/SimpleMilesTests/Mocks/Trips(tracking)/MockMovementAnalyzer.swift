//
//  MockMovementAnalyzer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import CoreLocation
@testable import SimpleMiles

final class MockMovementAnalyzer: MovementAnalyzerProtocol {
    var speedThreshold: CLLocationSpeed = 0
    var distanceThreshold: CLLocationDistance = 0

    // Configurable return values
    var isMovingResult: Bool = false
    var shouldResumeResult: Bool = false
    var isStayingStoppedResult: Bool = false
    var shouldStartTripResult: Bool = false
    var shouldStopTripResult: Bool = false

    func isMoving(speed: CLLocationSpeed?) -> Bool {
        isMovingResult
    }

    func shouldResume(from: CLLocation, lastStoppedLocation: CLLocation?) -> Bool {
        shouldResumeResult
    }

    func isStayingStopped(for durations: [TimeInterval]) -> Bool {
        isStayingStoppedResult
    }

    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double?) -> Bool {
        shouldStartTripResult
    }

    func shouldStopTrip(
        recentIdleDurations: [TimeInterval],
        speed: CLLocationSpeed?,
        acceleration: Double?,
        timeSinceIdleBegan: TimeInterval
    ) -> Bool {
        shouldStopTripResult
    }
}
