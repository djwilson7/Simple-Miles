//
//  MovementAnalyzerProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//
import CoreLocation

protocol MovementAnalyzerProtocol {
    var speedThreshold: CLLocationSpeed { get set }
    var distanceThreshold: CLLocationDistance { get set }

    func isMoving(speed: CLLocationSpeed?) -> Bool
    func shouldResume(from: CLLocation, lastStoppedLocation: CLLocation?) -> Bool
    func isStayingStopped(for durations: [TimeInterval]) -> Bool
    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double?) -> Bool
    func shouldStopTrip(
        recentIdleDurations: [TimeInterval],
        speed: CLLocationSpeed?,
        acceleration: Double?,
        timeSinceIdleBegan: TimeInterval
    ) -> Bool
}


