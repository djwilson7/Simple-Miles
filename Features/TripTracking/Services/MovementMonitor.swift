//
//  MovementMonitor.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

//
//  MovementMonitor.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
import CoreLocation

final class MovementMonitor: MovementMonitoringProtocol {
    private var analyzer: MovementAnalyzer
    private let stationaryThresholdDuration: TimeInterval = 5
    private let endSessionDuration: TimeInterval = 600
    private let stationaryDistanceThreshold: CLLocationDistance = 10

    private var lastLocation: CLLocation?
    private var pausedLocation: CLLocation?
    private var stationaryStartTime: Date?
    private var sessionStartTime: Date?
    private var lastMovementTime: Date?

    var onShouldStartTrip: (() -> Void)?
    var onShouldResumeTrip: (() -> Void)?
    var onShouldPauseTrip: (() -> Void)?

    init(analyzer: MovementAnalyzer) {
        self.analyzer = analyzer
    }

    func startPassiveMonitoring() {
        print("[MovementMonitor] startPassiveMonitoring triggered")
        resetState()
    }

    func resetState() {
        print("[MovementMonitor] resetState triggered")
        lastLocation = nil
        pausedLocation = nil
        stationaryStartTime = nil
        sessionStartTime = nil
        lastMovementTime = nil
    }

    func updateThresholds(speed: CLLocationSpeed, distance: CLLocationDistance) {
        print("[MovementMonitor] updateThresholds triggered with speed: \(speed), distance: \(distance)")
        analyzer.speedThreshold = speed
        analyzer.distanceThreshold = distance
    }

    func analyze(location: CLLocation) {
        print("[MovementMonitor] analyze triggered: \(location)")

        defer { lastLocation = location }

        guard let last = lastLocation else {
            print("[MovementMonitor] First coordinate received, initializing")
            return
        }

        let distance = location.distance(from: last)
        let now = Date()

        // Session hasn't started yet
        if sessionStartTime == nil {
            if analyzer.shouldStartTrip(speed: location.speed, acceleration: nil) {
                print("[MovementMonitor] onShouldStartTrip triggered")
                sessionStartTime = now
                lastMovementTime = now
                onShouldStartTrip?()
            }
            return
        }

        // Movement is detected
        if analyzer.isMoving(speed: location.speed) {
            print("[MovementMonitor] movement detected")
            lastMovementTime = now

            // Resume if paused
            if pausedLocation != nil {
                print("[MovementMonitor] onShouldResumeTrip triggered")
                pausedLocation = nil
                stationaryStartTime = nil
                onShouldResumeTrip?()
            }

            return
        }

        // No movement, check for stationary conditions
        if pausedLocation == nil {
            if stationaryStartTime == nil {
                print("[MovementMonitor] establishing stationary reference")
                stationaryStartTime = now
                return
            }

            let duration = now.timeIntervalSince(stationaryStartTime!)
            if duration >= stationaryThresholdDuration {
                print("[MovementMonitor] onShouldPauseTrip triggered")
                pausedLocation = location
                stationaryStartTime = nil
                onShouldPauseTrip?()
            } else {
                print("[MovementMonitor] stationary time accumulating: \(duration)")
            }
        }

        // Optionally, could trigger stopSession if desired
        if let lastMove = lastMovementTime {
            let idleTime = now.timeIntervalSince(lastMove)
            if idleTime >= endSessionDuration {
                print("[MovementMonitor] Trip should be ended (idleTime: \(idleTime)s within radius)")
                // Optional: Emit a future onShouldStopTrip?()
            }
        }
    }
}
