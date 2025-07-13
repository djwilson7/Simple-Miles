//
//  MovementAnalyzer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation
import CoreLocation

/// A utility responsible for interpreting motion patterns and suggesting actions.
struct MovementAnalyzer: MovementAnalyzing {
    
    /// Threshold (in meters per second) to consider a vehicle as moving.
    private let movementSpeedThreshold: CLLocationSpeed = 5.0

    /// Time interval (in seconds) that defines prolonged idleness.
    private let idleThreshold: TimeInterval = 60.0
    
    func isMoving(speed: CLLocationSpeed?) -> Bool {
        guard let speed = speed else { return false }
        return speed >= movementSpeedThreshold
    }

    func isStayingStopped(for recentIdleDurations: [TimeInterval]) -> Bool {
        return recentIdleDurations.suffix(3).allSatisfy { $0 > idleThreshold }
    }

    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double? = nil) -> Bool {
        let fastEnough = (speed ?? 0) > movementSpeedThreshold
        let suddenMovement = (acceleration ?? 0) > 1.5
        return fastEnough || suddenMovement
    }

    func shouldStopTrip(
        recentIdleDurations: [TimeInterval],
        speed: CLLocationSpeed?,
        acceleration: Double? = nil
    ) -> Bool {
        let noMotion = (speed ?? 0) < 1.0 && (acceleration ?? 0) < 0.5
        return isStayingStopped(for: recentIdleDurations) && noMotion
    }
}
