//
//  CSVTripWriterTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class CSVTripWriterTests: XCTestCase {
    func testExportReturnsNilForEmptyTrips() {
        XCTAssertNil(CSVTripWriter.export(from: []))
    }

    func testExportReturnsValidCSVFileWithCorrectExtension() {
        let result = CSVTripWriter.export(from: [TripSessionModel.mock()])
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.path.hasSuffix(".csv") == true)
    }

    func testExportIncludesHeaderRowAndTripData() throws {
        let url = try XCTUnwrap(CSVTripWriter.export(from: [TripSessionModel.mock()]))
        let content = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(content.contains("trip_id"))
        XCTAssertTrue(content.contains("distance_miles"))
    }
    
    func testExportIncludesMultipleDataRows() throws {
        let trips = [TripSessionModel.mock(), TripSessionModel.mock()]
        let url = try XCTUnwrap(CSVTripWriter.export(from: trips))
        let content = try String(contentsOf: url, encoding: .utf8)

        let rows = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        XCTAssertEqual(rows.count, trips.count + 1, "Should include 1 header and 1 row per trip")
    }

    func testExportHandlesZeroDistanceAndEmptySegments() throws {
        let trip = TripSessionModel(distance: 0.0, segments: [])
        let url = try XCTUnwrap(CSVTripWriter.export(from: [trip]))
        let content = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(content.contains("0.00"), "Distance should fallback to 0.00 miles")
    }

    func testExportHandlesMinimalTripFields() throws {
        let minimalTrip = TripSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            distance: 0,
            segments: []
        )

        let url = try XCTUnwrap(CSVTripWriter.export(from: [minimalTrip]))
        let content = try String(contentsOf: url, encoding: .utf8)

        XCTAssertTrue(content.contains(minimalTrip.id.uuidString))
    }
}
