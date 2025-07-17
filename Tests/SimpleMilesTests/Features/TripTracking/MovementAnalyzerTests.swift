//
//  MovementAnalyzerTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

// MovementAnalyzerTests.swift

import XCTest
import CoreLocation
@testable import SimpleMiles

final class MovementAnalyzerTests: XCTestCase {
    private var analyzer: MovementAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = MovementAnalyzer(speedThreshold: 2.5, distanceThreshold: 50)
    }

    // MARK: - isMoving

    func test_isMoving_nilSpeed_returnsFalse() {
        XCTAssertFalse(analyzer.isMoving(speed: nil))
    }

    func test_isMoving_exactThreshold_returnsTrue() {
        XCTAssertTrue(analyzer.isMoving(speed: 2.5))
    }

    func test_isMoving_belowThreshold_returnsFalse() {
        XCTAssertFalse(analyzer.isMoving(speed: 2.49))
    }

    func test_isMoving_aboveThreshold_returnsTrue() {
        XCTAssertTrue(analyzer.isMoving(speed: 2.51))
    }

    // MARK: - shouldResume

    func test_shouldResume_nilLastLocation_returnsFalse() {
        let moved = CLLocation(latitude: 1, longitude: 1)
        XCTAssertFalse(analyzer.shouldResume(from: moved, lastStoppedLocation: nil))
    }

    func test_shouldResume_withinDistance_returnsFalse() {
        let from = CLLocation(latitude: 0, longitude: 0)
        let to = CLLocation(latitude: 0.0001, longitude: 0.0001) // ~15m
        XCTAssertFalse(analyzer.shouldResume(from: to, lastStoppedLocation: from))
    }

    func test_shouldResume_exactThreshold_returnsTrue() {
        let from = CLLocation(latitude: 0, longitude: 0)
        let to = CLLocation(latitude: 0.0005, longitude: 0.0005) // ~78m
        XCTAssertTrue(analyzer.shouldResume(from: to, lastStoppedLocation: from))
    }

    // MARK: - isStayingStopped

    func test_isStayingStopped_allAboveIdleThreshold_returnsTrue() {
        XCTAssertTrue(analyzer.isStayingStopped(for: [65, 70, 75]))
    }

    func test_isStayingStopped_anyBelowIdleThreshold_returnsFalse() {
        XCTAssertFalse(analyzer.isStayingStopped(for: [30, 90, 70]))
    }

    func test_isStayingStopped_emptyDurations_returnsFalse() {
        XCTAssertFalse(analyzer.isStayingStopped(for: []))
    }

    // MARK: - shouldStartTrip

    func test_shouldStartTrip_nilInputs_returnsFalse() {
        XCTAssertFalse(analyzer.shouldStartTrip(speed: nil, acceleration: nil))
    }

    func test_shouldStartTrip_onlySpeedQualifies_returnsTrue() {
        XCTAssertTrue(analyzer.shouldStartTrip(speed: 3.0, acceleration: 0.1))
    }

    func test_shouldStartTrip_onlyAccelerationQualifies_returnsTrue() {
        XCTAssertTrue(analyzer.shouldStartTrip(speed: 1.0, acceleration: 2.0))
    }

    func test_shouldStartTrip_bothInputsTooLow_returnsFalse() {
        XCTAssertFalse(analyzer.shouldStartTrip(speed: 1.0, acceleration: 1.0))
    }

    // MARK: - shouldStopTrip

    func test_shouldStopTrip_allConditionsMet_returnsTrue() {
        let result = analyzer.shouldStopTrip(
            recentIdleDurations: [61, 62, 70],
            speed: 0.2,
            acceleration: 0.1,
            timeSinceIdleBegan: 121
        )
        XCTAssertTrue(result)
    }

    func test_shouldStopTrip_anyConditionFails_returnsFalse() {
        let result = analyzer.shouldStopTrip(
            recentIdleDurations: [30, 20, 40],
            speed: 0.2,
            acceleration: 0.1,
            timeSinceIdleBegan: 130
        )
        XCTAssertFalse(result)
    }

    func test_shouldStopTrip_highSpeed_preventsStop() {
        let result = analyzer.shouldStopTrip(
            recentIdleDurations: [70, 80, 90],
            speed: 3.0,
            acceleration: 0.1,
            timeSinceIdleBegan: 130
        )
        XCTAssertFalse(result)
    }

    func test_shouldStopTrip_shortIdleTime_preventsStop() {
        let result = analyzer.shouldStopTrip(
            recentIdleDurations: [70, 80, 90],
            speed: 0.1,
            acceleration: 0.1,
            timeSinceIdleBegan: 30
        )
        XCTAssertFalse(result)
    }

    func test_shouldStopTrip_nilAccelerationTreatsAsZero() {
        let result = analyzer.shouldStopTrip(
            recentIdleDurations: [70, 80, 90],
            speed: 0.1,
            acceleration: nil,
            timeSinceIdleBegan: 130
        )
        XCTAssertTrue(result)
    }

    func test_shouldStopTrip_nilSpeedTreatsAsZero() {
        let result = analyzer.shouldStopTrip(
            recentIdleDurations: [70, 80, 90],
            speed: nil,
            acceleration: 0.1,
            timeSinceIdleBegan: 130
        )
        XCTAssertTrue(result)
    }
}
