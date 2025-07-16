//
//  TripExportViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TripExportViewModelTests: XCTestCase {
    func testGenerateCSVExportReturnsFileURLWhenTripsExist() {
        let mock = MockTripSessionStore()
        mock.stubbedSessions = [TripSessionModel.mock()]
        let sut = TripExportViewModel(store: mock)

        let url = sut.generateCSVExport()
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.hasSuffix(".csv") == true)
    }

    func testGenerateCSVExportReturnsNilWhenNoTrips() {
        let sut = TripExportViewModel(store: MockTripSessionStore())
        XCTAssertNil(sut.generateCSVExport())
    }

    func testGenerateJSONBackupReturnsFileURLWhenTripsExist() {
        let mock = MockTripSessionStore()
        mock.stubbedSessions = [TripSessionModel.mock()]
        let sut = TripExportViewModel(store: mock)

        let url = sut.generateJSONBackup()
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.path.hasSuffix(".json") == true)
    }

    func testGenerateJSONBackupReturnsNilWhenNoTrips() {
        let sut = TripExportViewModel(store: MockTripSessionStore())
        XCTAssertNil(sut.generateJSONBackup())
    }
    
    func testGeneratedCSVFileIsNonEmpty() {
        let mock = MockTripSessionStore()
        mock.stubbedSessions = [TripSessionModel.mock()]
        let sut = TripExportViewModel(store: mock)

        guard let url = sut.generateCSVExport() else {
            XCTFail("Expected file URL")
            return
        }

        let contents = try? String(contentsOf: url, encoding: .utf8)
        XCTAssertNotNil(contents)
        XCTAssertFalse(contents!.isEmpty, "CSV should not be empty")
    }
    
    func testGeneratedJSONFileIsNonEmpty() {
        let mock = MockTripSessionStore()
        mock.stubbedSessions = [TripSessionModel.mock()]
        let sut = TripExportViewModel(store: mock)

        guard let url = sut.generateJSONBackup() else {
            XCTFail("Expected file URL")
            return
        }

        let contents = try? String(contentsOf: url, encoding: .utf8)
        XCTAssertNotNil(contents)
        XCTAssertFalse(contents!.isEmpty, "JSON should not be empty")
        XCTAssertTrue(contents!.contains("\"id\""), "JSON should include trip ID")
    }

    func testCSVExportIncludesMultipleTrips() {
        let mock = MockTripSessionStore()
        mock.stubbedSessions = [TripSessionModel.mock(), TripSessionModel.mock()]
        let sut = TripExportViewModel(store: mock)

        guard let url = sut.generateCSVExport(),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            XCTFail("Expected valid CSV export")
            return
        }

        let lineCount = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.count
        XCTAssertEqual(lineCount, 3, "Should contain 1 header + 2 data rows")
    }

    func testCSVHandlesZeroDistanceAndNoSegments() {
        let mockTrip = TripSessionModel(distance: 0, segments: [])
        let mock = MockTripSessionStore()
        mock.stubbedSessions = [mockTrip]
        let sut = TripExportViewModel(store: mock)

        guard let url = sut.generateCSVExport(),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            XCTFail("Expected CSV export")
            return
        }

        XCTAssertTrue(contents.contains("0.00"), "Should show 0.00 miles")
    }

}
