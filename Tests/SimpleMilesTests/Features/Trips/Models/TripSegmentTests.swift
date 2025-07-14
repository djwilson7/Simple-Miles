//
//  TripSegmentTests.swift
//  SimpleMilesTests
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
@testable import SimpleMiles

final class TripSegmentTests: XCTestCase {
    
    // MARK: - Helper
    
    private func makeCoordinate(lat: Double = 37.0, lon: Double = -122.0) -> CoordinateModel {
        return CoordinateModel(latitude: lat, longitude: lon)
    }
    
    // MARK: - Tests

    func testInitializationWithValidData() {
        let start = Date()
        let end = start.addingTimeInterval(60)
        let segment = TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(lat: 37.01, lon: -122.01),
            distance: 600.0
        )
        
        XCTAssertEqual(segment.duration, 60)
        XCTAssertEqual(segment.speed, 10.0)
        XCTAssertEqual(segment.distance, 600.0)
        XCTAssertEqual(segment.startCoordinate.latitude, 37.0)
        XCTAssertEqual(segment.endCoordinate.latitude, 37.01)
    }

    func testZeroDurationReturnsZeroSpeed() {
        let now = Date()
        let segment = TripSegmentModel(
            startTime: now,
            endTime: now,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(),
            distance: 0
        )
        
        XCTAssertEqual(segment.speed, 0.0)
        XCTAssertEqual(segment.duration, 0.0)
    }

    func testNegativeDistanceStillInitializes() {
        let start = Date()
        let end = start.addingTimeInterval(10)
        let segment = TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(),
            distance: -50.0
        )
        
        XCTAssertEqual(segment.distance, -50.0)
        XCTAssertEqual(segment.speed, -5.0)
    }

    func testSpeedCalculationPrecision() {
        let start = Date()
        let end = start.addingTimeInterval(5)
        let segment = TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(),
            distance: 50.0
        )
        
        XCTAssertEqual(segment.speed, 10.0, accuracy: 0.001)
    }

    func testDurationCalculation() {
        let start = Date()
        let end = start.addingTimeInterval(120)
        let segment = TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(),
            distance: 240.0
        )
        
        XCTAssertEqual(segment.duration, 120.0)
        XCTAssertEqual(segment.speed, 2.0)
    }

    func testDifferentIDsAreUnique() {
        let start = Date()
        let end = start.addingTimeInterval(30)

        let seg1 = TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(),
            distance: 30.0
        )

        let seg2 = TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(),
            distance: 30.0
        )

        XCTAssertNotEqual(seg1.id, seg2.id)
    }
}
