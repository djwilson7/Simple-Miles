//
//  TripExportViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class TripExportViewModelTests: XCTestCase {
    private var viewModel: TripExportViewModel!
    private var mockStore: MockTripSessionStore!
    private var mockCSVExporter: MockCSVExporter!
    private var mockJSONExporter: MockJSONExporter!

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
        mockCSVExporter = MockCSVExporter()
        mockJSONExporter = MockJSONExporter()

        viewModel = TripExportViewModel(
            store: mockStore,
            csvExporter: mockCSVExporter,
            jsonExporter: mockJSONExporter
        )
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        mockCSVExporter = nil
        mockJSONExporter = nil
        super.tearDown()
    }

    func test_generateCSVExport_returnsURL_whenTripsExist() {
        mockStore.save(TripSessionModel())
        let result = viewModel.generateCSVExport()

        XCTAssertTrue(mockCSVExporter.exportCalled)
        XCTAssertEqual(mockCSVExporter.exportedTrips.count, 1)
        XCTAssertEqual(result, mockCSVExporter.exportURLToReturn)
    }

    func test_generateCSVExport_returnsNil_whenNoTripsExist() {
        mockStore.mockTrips = []
        mockCSVExporter.exportURLToReturn = nil

        let result = viewModel.generateCSVExport()

        XCTAssertTrue(mockCSVExporter.exportCalled)
        XCTAssertTrue(mockCSVExporter.exportedTrips.isEmpty)
        XCTAssertNil(result)
    }

    func test_generateJSONBackup_returnsURL_whenTripsExist() {
        mockStore.save(TripSessionModel())
        let result = viewModel.generateJSONBackup()

        XCTAssertTrue(mockJSONExporter.exportCalled)
        XCTAssertEqual(mockJSONExporter.exportedTrips.count, 1)
        XCTAssertEqual(result, mockJSONExporter.exportURLToReturn)
    }

    func test_generateJSONBackup_returnsNil_whenNoTripsExist() {
        mockStore.mockTrips = []
        mockJSONExporter.exportURLToReturn = nil

        let result = viewModel.generateJSONBackup()

        XCTAssertTrue(mockJSONExporter.exportCalled)
        XCTAssertTrue(mockJSONExporter.exportedTrips.isEmpty)
        XCTAssertNil(result)
    }
}
