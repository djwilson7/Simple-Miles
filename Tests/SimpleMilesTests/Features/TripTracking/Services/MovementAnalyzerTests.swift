//
//  MovementAnalyzerTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
import CoreLocation
@testable import SimpleMiles

final class MovementAnalyzerTests: XCTestCase {
    private var analyzer: MovementAnalyzer!

    override func setUp() {
        super.setUp()
        analyzer = MovementAnalyzer()
    }

    override func tearDown() {
        analyzer = nil
        super.tearDown()
    }

    // MARK: - isMoving(speed:)

    func testIsMoving_nilSpeed_returnsFalse() {
        XCTAssertFalse(analyzer.isMoving(speed: nil))
    }

    func testIsMoving_belowThreshold_returnsFalse() {
        XCTAssertFalse(analyzer.isMoving(speed: 4.99))
    }

    func testIsMoving_atThreshold_returnsTrue() {
        XCTAssertTrue(analyzer.isMoving(speed: 5.0))
    }

    func testIsMoving_aboveThreshold_returnsTrue() {
        XCTAssertTrue(analyzer.isMoving(speed: 5.1))
    }

    // MARK: - isStayingStopped(for:)

    func testIsStayingStopped_withThreeLongIdleDurations_returnsTrue() {
        let durations: [TimeInterval] = [10, 70, 80, 90]
        XCTAssertTrue(analyzer.isStayingStopped(for: durations))
    }

    func testIsStayingStopped_withAnyShortDuration_returnsFalse() {
        let durations: [TimeInterval] = [70, 50, 80]
        XCTAssertFalse(analyzer.isStayingStopped(for: durations))
    }

    // MARK: - shouldStartTrip(speed:acceleration:)

    func testShouldStartTrip_bySpeed() {
        XCTAssertTrue(analyzer.shouldStartTrip(speed: 6.0, acceleration: nil))
    }

    func testShouldStartTrip_byAcceleration() {
        XCTAssertTrue(analyzer.shouldStartTrip(speed: 0.0, acceleration: 2.0))
    }

    func testShouldStartTrip_noMotion_returnsFalse() {
        XCTAssertFalse(analyzer.shouldStartTrip(speed: 0.0, acceleration: 0.0))
    }

    // MARK: - shouldStopTrip(recentIdleDurations:speed:acceleration:)

    func testShouldStopTrip_whenIdleAndNoMotion_returnsTrue() {
        let durations: [TimeInterval] = [70, 80, 90]
        XCTAssertTrue(
            analyzer.shouldStopTrip(
                recentIdleDurations: durations,
                speed: 0.5,
                acceleration: 0.0
            )
        )
    }

    func testShouldStopTrip_whenMovingOrNotIdle_returnsFalse() {
        let durations1: [TimeInterval] = [70, 80, 90]
        XCTAssertFalse(
            analyzer.shouldStopTrip(
                recentIdleDurations: durations1,
                speed: 2.0,
                acceleration: 0.0
            )
        )
        let durations2: [TimeInterval] = [10, 20, 30]
        XCTAssertFalse(
            analyzer.shouldStopTrip(
                recentIdleDurations: durations2,
                speed: 0.0,
                acceleration: 0.0
            )
        )
    }
}
