//  MockMovementMonitor.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import CoreLocation
@testable import SimpleMiles

final class MockMovementMonitor: MovementMonitoringProtocol {
    private(set) var lastSpeed: CLLocationSpeed?
    private(set) var lastDistance: CLLocationDistance?
    private(set) var didResetState = false
    private(set) var didStartPassive = false
    private(set) var didAnalyze = false

    var onShouldStartTrip: (() -> Void)?
    var onShouldResumeTrip: (() -> Void)?
    var onShouldPauseTrip: (() -> Void)?
    var onShouldStopTrip: (() -> Void)? // Newly added

    func updateThresholds(speed: CLLocationSpeed, distance: CLLocationDistance) {
        lastSpeed = speed
        lastDistance = distance
    }

    func startPassiveMonitoring() {
        didStartPassive = true
    }

    func analyze(location: CLLocation) {
        didAnalyze = true
    }

    func resetState() {
        didResetState = true
    }
}
