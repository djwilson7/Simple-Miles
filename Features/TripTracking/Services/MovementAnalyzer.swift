//
//  MovementAnalyzer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation
import CoreLocation

struct MovementAnalyzer: MovementAnalyzerProtocol {
    var speedThreshold: CLLocationSpeed = 2.5
    var distanceThreshold: CLLocationDistance = 50.0
    
    private let idleThreshold: TimeInterval = 60.0
    private let gracePeriodBeforeStop: TimeInterval = 120.0

    func isMoving(speed: CLLocationSpeed?) -> Bool {
        guard let speed = speed else { return false }
        return speed >= speedThreshold
    }

    func shouldResume(from location: CLLocation, lastStoppedLocation: CLLocation?) -> Bool {
        guard let last = lastStoppedLocation else { return false }
        let dist = location.distance(from: last)
        return dist >= distanceThreshold
    }

    func isStayingStopped(for recentIdleDurations: [TimeInterval]) -> Bool {
        return recentIdleDurations.suffix(3).allSatisfy { $0 > idleThreshold }
    }

    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double?) -> Bool {
        let fastEnough = (speed ?? 0) > speedThreshold
        let suddenMovement = (acceleration ?? 0) > 1.5
        return fastEnough || suddenMovement
    }

    func shouldStopTrip(
        recentIdleDurations: [TimeInterval],
        speed: CLLocationSpeed?,
        acceleration: Double?,
        timeSinceIdleBegan: TimeInterval
    ) -> Bool {
        let noMotion = (speed ?? 0) < 1.0 && (acceleration ?? 0) < 0.5
        return isStayingStopped(for: recentIdleDurations)
            && noMotion
            && timeSinceIdleBegan > gracePeriodBeforeStop
    }
}
