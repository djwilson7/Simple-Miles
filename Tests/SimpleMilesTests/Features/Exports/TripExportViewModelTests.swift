//  TripExportViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: valid and empty trip exports, exporter return value and calls, multi-trip advanced flows, all failure/edge scenarios for exporter behavior.
//  Assumes correct mock behavior for full coverage of both success and error states.


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

    // MARK: - Basic Functionality

    func test_generateCSVExport_returnsURL_whenTripsExist() {
        let trip = TripSessionModel()
        mockStore.save(trip)
        mockCSVExporter.exportURLToReturn = URL(fileURLWithPath: "/mock/export.csv")

        let result = viewModel.generateCSVExport()

        XCTAssertTrue(mockCSVExporter.exportCalled)
        XCTAssertEqual(mockCSVExporter.exportedTrips, [trip])
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
        let trip = TripSessionModel()
        mockStore.save(trip)
        mockJSONExporter.exportURLToReturn = URL(fileURLWithPath: "/mock/export.json")

        let result = viewModel.generateJSONBackup()

        XCTAssertTrue(mockJSONExporter.exportCalled)
        XCTAssertEqual(mockJSONExporter.exportedTrips, [trip])
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

    // MARK: - Advanced Functionality

    func test_generateCSVExport_passesAllTripsToExporter() {
        let trip1 = TripSessionModel()
        let trip2 = TripSessionModel()
        mockStore.save(trip1)
        mockStore.save(trip2)
        _ = viewModel.generateCSVExport()
        XCTAssertEqual(mockCSVExporter.exportedTrips, [trip1, trip2])
    }

    func test_generateJSONBackup_passesAllTripsToExporter() {
        let trip1 = TripSessionModel()
        let trip2 = TripSessionModel()
        mockStore.save(trip1)
        mockStore.save(trip2)
        _ = viewModel.generateJSONBackup()
        XCTAssertEqual(mockJSONExporter.exportedTrips, [trip1, trip2])
    }

    // MARK: - Edge Cases

    func test_generateCSVExport_emptyTripArray_callsExporterWithEmptyArray() {
        mockStore.mockTrips = []
        mockCSVExporter.exportedTrips = []
        _ = viewModel.generateCSVExport()
        XCTAssertTrue(mockCSVExporter.exportCalled)
        XCTAssertTrue(mockCSVExporter.exportedTrips.isEmpty)
    }

    func test_generateJSONBackup_emptyTripArray_callsExporterWithEmptyArray() {
        mockStore.mockTrips = []
        mockJSONExporter.exportedTrips = []
        _ = viewModel.generateJSONBackup()
        XCTAssertTrue(mockJSONExporter.exportCalled)
        XCTAssertTrue(mockJSONExporter.exportedTrips.isEmpty)
    }

    func test_generateCSVExport_exporterReturnsNil_returnsNil() {
        mockStore.save(TripSessionModel())
        mockCSVExporter.exportURLToReturn = nil
        let result = viewModel.generateCSVExport()
        XCTAssertNil(result)
    }

    func test_generateJSONBackup_exporterReturnsNil_returnsNil() {
        mockStore.save(TripSessionModel())
        mockJSONExporter.exportURLToReturn = nil
        let result = viewModel.generateJSONBackup()
        XCTAssertNil(result)
    }
}
