// MovementMonitor.swift
// SimpleMiles

import Foundation
import CoreLocation

final class MovementMonitor: MovementMonitoringProtocol {
    private var analyzer: MovementAnalyzerProtocol
    private let stationaryThresholdDuration: TimeInterval = 0.5
    private let endSessionDuration: TimeInterval = 600
    private let stationaryDistanceThreshold: CLLocationDistance = 12

    private var lastLocation: CLLocation?
    private var pausedLocation: CLLocation?
    private var stationaryStartTime: Date?
    private var sessionStartTime: Date?
    private var lastMovementTime: Date?

    var onShouldStartTrip: (() -> Void)?
    var onShouldResumeTrip: (() -> Void)?
    var onShouldPauseTrip: (() -> Void)?
    var onShouldStopTrip: (() -> Void)?

    init(analyzer: MovementAnalyzerProtocol) {
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
        print("[MovementMonitor] updateThresholds: speed=\(speed), distance=\(distance)")
        analyzer.speedThreshold = speed
        analyzer.distanceThreshold = distance
    }

    func analyze(location: CLLocation) {
        print("[MovementMonitor] analyze triggered: \(location.coordinate)")

        defer { lastLocation = location }

        guard let last = lastLocation else {
            print("[MovementMonitor] First coordinate received, initializing")
            return
        }

        let distanceFromLast = location.distance(from: last)
        let now = Date()
        print("[MovementMonitor] distance from last: \(distanceFromLast)")

        if sessionStartTime == nil {
            if analyzer.shouldStartTrip(speed: location.speed, acceleration: nil) {
                print("[MovementMonitor] onShouldStartTrip triggered")
                sessionStartTime = now
                lastMovementTime = now
                onShouldStartTrip?()
            }
            return
        }

        if analyzer.isMoving(speed: location.speed) {
            print("[MovementMonitor] movement detected")
            lastMovementTime = now

            if pausedLocation != nil {
                print("[MovementMonitor] onShouldResumeTrip triggered")
                pausedLocation = nil
                stationaryStartTime = nil
                onShouldResumeTrip?()
            }

            return
        }

        if pausedLocation == nil {
            if distanceFromLast >= stationaryDistanceThreshold {
                print("[MovementMonitor] jitter too high for pause — reset (\(distanceFromLast)m)")
                stationaryStartTime = nil
                return
            }

            if stationaryStartTime == nil {
                print("[MovementMonitor] starting stationary timer")
                stationaryStartTime = now
                return
            }

            let duration = now.timeIntervalSince(stationaryStartTime!)
            if duration >= stationaryThresholdDuration {
                print("[MovementMonitor] onShouldPauseTrip triggered — stationary \(duration)s")
                pausedLocation = location
                stationaryStartTime = nil
                onShouldPauseTrip?()
            } else {
                print("[MovementMonitor] accumulating stationary time: \(duration)s")
            }
        }

        if let lastMove = lastMovementTime {
            let idleTime = now.timeIntervalSince(lastMove)
            if idleTime >= endSessionDuration {
                print("[MovementMonitor] onShouldStopTrip triggered — idle for \(idleTime)s")
                onShouldStopTrip?()
            }
        }
    }
}
