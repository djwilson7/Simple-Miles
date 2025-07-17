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
        print("[MovementAnalyzer] isMoving triggered with speed: \(String(describing: speed))") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let speed = speed else { return false }
        return speed >= speedThreshold
    }

    func shouldResume(from location: CLLocation, lastStoppedLocation: CLLocation?) -> Bool {
        print("[MovementAnalyzer] shouldResume triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let last = lastStoppedLocation else { return false }
        let dist = location.distance(from: last)
        return dist >= distanceThreshold
    }

    func isStayingStopped(for durations: [TimeInterval]) -> Bool {
        print("[MovementAnalyzer] isStayingStopped triggered with durations: \(durations)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard !durations.isEmpty else { return false }
        return durations.allSatisfy { $0 > 60 }
    }

    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double?) -> Bool {
        print("[MovementAnalyzer] shouldStartTrip triggered with speed: \(String(describing: speed)), acceleration: \(String(describing: acceleration))") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
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
        print("[MovementAnalyzer] shouldStopTrip triggered with speed: \(String(describing: speed)), acceleration: \(String(describing: acceleration)), idleDurations: \(recentIdleDurations), timeSinceIdleBegan: \(timeSinceIdleBegan)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let noMotion = (speed ?? 0) < 1.0 && (acceleration ?? 0) < 0.5
        return isStayingStopped(for: recentIdleDurations)
            && noMotion
            && timeSinceIdleBegan > gracePeriodBeforeStop
    }
}
