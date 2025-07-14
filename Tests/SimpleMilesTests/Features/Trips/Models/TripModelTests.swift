//
//  TripModelTests.swift
//  Simple Miles Tests
//
//  Created by Invictus Maneo on 7/12/25.
//

import XCTest
import CoreLocation
@testable import SimpleMiles

final class TripModelTests: XCTestCase {

    func testDurationCalculation() {
        let start = Date()
        let end = start.addingTimeInterval(300) // 5 minutes

        let trip = TripModel(
            startTime: start,
            endTime: end,
            tripType: .business,
            distance: 500,
            route: []
        )

        XCTAssertEqual(trip.duration, 300, accuracy: 0.001)
    }

    func testIsShortTripTrueWhenShortDuration() {
        let start = Date()
        let end = start.addingTimeInterval(10) // 10 seconds

        let trip = TripModel(
            startTime: start,
            endTime: end,
            tripType: .personal,
            distance: 500,
            route: []
        )

        XCTAssertTrue(trip.isShortTrip)
    }

    func testIsShortTripTrueWhenShortDistance() {
        let start = Date()
        let end = start.addingTimeInterval(300)

        let trip = TripModel(
            startTime: start,
            endTime: end,
            tripType: .personal,
            distance: 50, // short distance
            route: []
        )

        XCTAssertTrue(trip.isShortTrip)
    }

    func testIsShortTripFalseWhenLongEnough() {
        let start = Date()
        let end = start.addingTimeInterval(300)

        let trip = TripModel(
            startTime: start,
            endTime: end,
            tripType: .business,
            distance: 1000,
            route: []
        )

        XCTAssertFalse(trip.isShortTrip)
    }

    func testCodableRoundTrip() throws {
        let start = Date()
        let end = start.addingTimeInterval(120)
        let route = [CoordinateModel(latitude: 32.7767, longitude: -96.7970)]

        let trip = TripModel(
            startTime: start,
            endTime: end,
            tripType: .unclassified,
            distance: 200,
            route: route,
            averageSpeed: 30.0,
            userNotes: "Test trip",
            regionIdentifier: "75201"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(trip)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TripModel.self, from: data)

        XCTAssertEqual(trip.id, decoded.id)
        XCTAssertEqual(Int(trip.startTime.timeIntervalSince1970), Int(decoded.startTime.timeIntervalSince1970))
        XCTAssertEqual(Int(trip.endTime.timeIntervalSince1970), Int(decoded.endTime.timeIntervalSince1970))
        XCTAssertEqual(trip.tripType, decoded.tripType)
        XCTAssertEqual(trip.distance, decoded.distance, accuracy: 0.001)
        XCTAssertEqual(trip.averageSpeed, decoded.averageSpeed)
        XCTAssertEqual(trip.userNotes, decoded.userNotes)
        XCTAssertEqual(trip.regionIdentifier, decoded.regionIdentifier)
        XCTAssertEqual(trip.route.count, decoded.route.count)
    }
}
