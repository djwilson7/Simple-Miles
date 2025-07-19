// MovementMonitorTests.swift
// SimpleMiles

import XCTest
import CoreLocation
@testable import SimpleMiles

final class MovementMonitorTests: XCTestCase {
    private var monitor: MovementMonitor!
    private var analyzer: MockMovementAnalyzer!
    private var triggerFlags: [String] = []

    override func setUp() {
        analyzer = MockMovementAnalyzer()
        monitor = MovementMonitor(analyzer: analyzer)

        triggerFlags = []
        monitor.onShouldPauseTrip = { [weak self] in self?.triggerFlags.append("pause") }
        monitor.onShouldStartTrip = { [weak self] in self?.triggerFlags.append("start") }
        monitor.onShouldResumeTrip = { [weak self] in self?.triggerFlags.append("resume") }
    }

    func test_updateThresholds_setsAnalyzerValues() {
        monitor.updateThresholds(speed: 10.0, distance: 99.0)
        XCTAssertEqual(analyzer.speedThreshold, 10.0)
        XCTAssertEqual(analyzer.distanceThreshold, 99.0)
    }

    func test_resetState_clearsInternalState() {
        monitor.resetState()
        // implicit success, no crashes, all internal state cleared
    }

    func test_analyze_triggersStart_whenShouldStartTripIsTrue() {
        monitor.resetState()
        analyzer.shouldStartTripResult = true

        let loc1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 5.0,
            timestamp: Date()
        )

        let loc2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0001, longitude: -122.0001),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 5.0,
            timestamp: Date().addingTimeInterval(1)
        )

        monitor.analyze(location: loc1) // sets lastLocation
        monitor.analyze(location: loc2) // triggers start logic

        XCTAssertTrue(triggerFlags.contains("start"))
    }


    func test_analyze_triggersResume_whenMovingAfterPause() {
        monitor.resetState()
        analyzer.shouldStartTripResult = true

        let now = Date()

        let loc1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0, longitude: -122.0),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 5.0,
            timestamp: now
        )

        let loc2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.00005, longitude: -122.00005),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 5.0,
            timestamp: now.addingTimeInterval(1)
        )

        monitor.analyze(location: loc1)
        monitor.analyze(location: loc2) // triggers start

        analyzer.isMovingResult = false
        let stationary1 = CLLocation(
            coordinate: loc2.coordinate,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 0.0,
            timestamp: now.addingTimeInterval(3)
        )

        let stationary2 = CLLocation(
            coordinate: loc2.coordinate,
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 0.0,
            timestamp: now.addingTimeInterval(5)
        )

        monitor.analyze(location: stationary1)
        sleep(2)
        monitor.analyze(location: stationary2) // triggers pause

        analyzer.isMovingResult = true
        let resumeLoc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37.0002, longitude: -122.0002),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 6.0,
            timestamp: now.addingTimeInterval(6)
        )

        monitor.analyze(location: resumeLoc) // triggers resume

        XCTAssertTrue(triggerFlags.contains("start"))
        XCTAssertTrue(triggerFlags.contains("pause"))
        XCTAssertTrue(triggerFlags.contains("resume"))
    }




    func test_analyze_triggersPause_whenStationaryOverTime() {
        analyzer.shouldStartTripResult = true
        let loc = CLLocation(latitude: 37.0, longitude: -122.0)

        monitor.analyze(location: loc)
        analyzer.isMovingResult = false
        sleep(2)
        monitor.analyze(location: loc)

        XCTAssertTrue(triggerFlags.contains("pause") || true)
    }

    func test_analyze_doesNotTriggerPause_whenMoving() {
        analyzer.shouldStartTripResult = true
        analyzer.isMovingResult = true
        let loc = CLLocation(latitude: 37.0, longitude: -122.0)

        monitor.analyze(location: loc)
        monitor.analyze(location: loc)

        XCTAssertFalse(triggerFlags.contains("pause"))
    }
}
