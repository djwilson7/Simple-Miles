//
//  TripSessionTests.swift
//  SimpleMilesTests
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
@testable import SimpleMiles

final class TripSessionTests: XCTestCase {
    
    // MARK: - Helpers
    
    private func makeCoordinate(lat: Double = 37.0, lon: Double = -122.0) -> CoordinateModel {
        return CoordinateModel(latitude: lat, longitude: lon)
    }
    
    private func makeSegment(
        distance: Double = 100.0,
        duration: TimeInterval = 10.0
    ) -> TripSegmentModel {
        let start = Date()
        let end = start.addingTimeInterval(duration)
        return TripSegmentModel(
            startTime: start,
            endTime: end,
            startCoordinate: makeCoordinate(),
            endCoordinate: makeCoordinate(lat: 37.01, lon: -122.01),
            distance: distance
        )
    }
    
    // MARK: - Tests
    
    func testSessionInitializesWithDefaults() {
        let session = TripSessionModel()
        
        XCTAssertNotNil(session.id)
        XCTAssertNotNil(session.startTime)
        XCTAssertNil(session.endTime)
        XCTAssertEqual(session.distance, 0.0)
        XCTAssertEqual(session.segments.count, 0)
        XCTAssertEqual(session.averageSpeed, 0.0)
    }
    
    func testAddSegmentAccumulatesDistance() {
        var session = TripSessionModel()
        let segment1 = makeSegment(distance: 100)
        let segment2 = makeSegment(distance: 50)
        
        session.addSegment(segment1)
        session.addSegment(segment2)
        
        XCTAssertEqual(session.segments.count, 2)
        XCTAssertEqual(session.distance, 150.0)
    }
    
    func testAverageSpeedCalculationIsCorrect() {
        let start = Date()
        let end = start.addingTimeInterval(60)
        var session = TripSessionModel(startTime: start)
        session.distance = 600.0
        session.endSession(at: end)
        
        XCTAssertEqual(session.averageSpeed, 10.0, accuracy: 0.001)
    }
    
    func testAverageSpeedWhenEndTimeIsNil() {
        let session = TripSessionModel()
        XCTAssertEqual(session.averageSpeed, 0.0)
    }
    
    func testEndingSessionUpdatesEndTime() {
        var session = TripSessionModel()
        let now = Date()
        session.endSession(at: now)
        
        XCTAssertEqual(session.endTime, now)
    }

    func testUUIDsAreUnique() {
        let session1 = TripSessionModel()
        let session2 = TripSessionModel()
        XCTAssertNotEqual(session1.id, session2.id)
    }

    func testEmptySegmentsDoNotCrashAverageSpeed() {
        var session = TripSessionModel()
        session.endSession(at: Date().addingTimeInterval(1))
        XCTAssertEqual(session.segments.count, 0)
        XCTAssertEqual(session.averageSpeed, 0.0, accuracy: 0.01)
    }

    func testMultipleSegmentDurationsCanBeSummedViaDistance() {
        var session = TripSessionModel()
        session.addSegment(makeSegment(distance: 200))
        session.addSegment(makeSegment(distance: 300))
        session.endSession(at: session.startTime.addingTimeInterval(100))

        XCTAssertEqual(session.distance, 500)
        XCTAssertEqual(session.averageSpeed, 5.0, accuracy: 0.01)
    }
}
