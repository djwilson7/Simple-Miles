//
//  CSVExportSchemaTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class CSVExportSchemaTests: XCTestCase {
    func testInitializationFromModelMapsFieldsCorrectly() {
        let trip = TripSessionModel.mock()
        let schema = CSVExportSchema(from: trip)

        XCTAssertEqual(schema.tripID, trip.id)
        XCTAssertEqual(schema.tripType, trip.tripType.rawValue)
        XCTAssertEqual(schema.segmentCount, trip.segments.count)
    }

    func testToCSVRowFormatsValuesProperly() {
        let trip = TripSessionModel.mock(distance: 1609.34) // 1 mile
        let schema = CSVExportSchema(from: trip)
        let row = schema.toCSVRow()

        XCTAssertTrue(row.contains("1.00"), "Should convert meters to miles")
        XCTAssertTrue(row.contains(schema.tripID.uuidString), "Should include trip ID")
    }

    func testHandlesEmptySegmentCoordinatesGracefully() {
        let trip = TripSessionModel.mock(segments: [])
        let schema = CSVExportSchema(from: trip)

        XCTAssertEqual(schema.startLat, 0)
        XCTAssertEqual(schema.endLon, 0)
    }
    
    func testSchemaWithNilEndTimeDefaultsToStartTime() {
        var trip = TripSessionModel.mock()
        trip.endTime = nil
        let schema = CSVExportSchema(from: trip)

        XCTAssertEqual(schema.durationMinutes, 0, accuracy: 0.1)
        XCTAssertEqual(schema.endTime, schema.startTime)
    }

    func testZeroDistanceStillFormatsCorrectly() {
        let trip = TripSessionModel.mock(distance: 0)
        let schema = CSVExportSchema(from: trip)
        let row = schema.toCSVRow()

        XCTAssertTrue(row.contains("0.00"), "Should format 0 meters/miles cleanly")
    }

    func testCoordinatePrecisionRoundsToSixDecimals() {
        let segment = TripSegmentModel.mock(
            startCoordinate: .init(latitude: 37.774929123456, longitude: -122.419416987654),
            endCoordinate: .init(latitude: 37.775000000000, longitude: -122.420000000000)
        )
        let trip = TripSessionModel.mock(segments: [segment])
        let schema = CSVExportSchema(from: trip)
        let row = schema.toCSVRow()

        XCTAssertTrue(row.contains("37.774929"), "Should round latitude to 6 decimals")
        XCTAssertTrue(row.contains("-122.419417"), "Should round longitude to 6 decimals")
    }

}
