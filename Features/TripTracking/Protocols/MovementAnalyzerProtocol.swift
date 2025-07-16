//
//  MovementAnalyzerProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//
import CoreLocation

protocol MovementAnalyzerProtocol {
    func isMoving(speed: CLLocationSpeed?) -> Bool
    func isStayingStopped(for durations: [TimeInterval]) -> Bool
    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double?) -> Bool
    func shouldStopTrip(
        recentIdleDurations: [TimeInterval],
        speed: CLLocationSpeed?,
        acceleration: Double?,
        timeSinceIdleBegan: TimeInterval
    ) -> Bool
    func shouldResume(from location: CLLocation, lastStoppedLocation: CLLocation?) -> Bool
}

