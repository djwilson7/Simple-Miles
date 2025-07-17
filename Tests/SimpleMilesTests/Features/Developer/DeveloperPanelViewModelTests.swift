//
//  DeveloperPanelViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class DeveloperPanelViewModelTests: XCTestCase {
    private var viewModel: DeveloperPanelViewModel!
    private var mockTripService: MockTripTrackingService!
    private var mockExportViewModel: MockTripExportViewModel!
    private var mockExportLauncher: MockExportLauncher!

    override func setUp() {
        super.setUp()
        mockTripService = MockTripTrackingService()
        mockExportViewModel = MockTripExportViewModel()
        mockExportLauncher = MockExportLauncher()

        viewModel = DeveloperPanelViewModel(
            tripService: mockTripService,
            exportViewModel: mockExportViewModel,
            exportLauncher: mockExportLauncher
        )
    }

    override func tearDown() {
        viewModel = nil
        mockTripService = nil
        mockExportViewModel = nil
        mockExportLauncher = nil
        super.tearDown()
    }

    func test_toggleTracking_startsRecordingWhenIdle() {
        viewModel.isTracking = false
        viewModel.toggleTracking()
        XCTAssertTrue(mockTripService.didStartRecording)
    }

    func test_toggleTracking_stopsRecordingWhenTracking() {
        viewModel.isTracking = true
        viewModel.toggleTracking()
        XCTAssertTrue(mockTripService.didStopRecording)
    }

    func test_exportAllTripsAsCSV_triggersExportAndLauncher() {
        viewModel.exportAllTripsAsCSV()
        XCTAssertEqual(mockExportLauncher.launchedURL, mockExportViewModel.exportedCSVURL)
        XCTAssertTrue(mockExportLauncher.isPresenting)
        XCTAssertEqual(viewModel.savedTripCount, 0)
    }

    func test_exportAllTripsAsJSON_triggersExportAndLauncher() {
        viewModel.exportAllTripsAsJSON()
        XCTAssertEqual(mockExportLauncher.launchedURL, mockExportViewModel.exportedJSONURL)
        XCTAssertTrue(mockExportLauncher.isPresenting)
        XCTAssertEqual(viewModel.savedTripCount, 0)
    }

    func test_refreshTripCount_updatesSavedTripCount() {
        let trip = TripSessionModel()
        let store = MockTripSessionStore()
        store.save(trip)

        mockExportViewModel.store = store
        viewModel.refreshTripCount()
        XCTAssertEqual(viewModel.savedTripCount, 1)
    }

    func test_resetPauseTimer_triggersRecordingState() {
        let mockState = mockTripService.recordingState as! MockTripRecordingState
        viewModel.resetPauseTimer()
        XCTAssertTrue(mockState.didResetPause)
    }


    func test_forceEndTrip_stopsAndResets() {
        viewModel.forceEndTrip()
        XCTAssertTrue(mockTripService.didStopRecording)
        XCTAssertTrue(mockTripService.didStartPassiveMonitoring)
        XCTAssertFalse(viewModel.isPaused)
    }

    func test_clearAllTrips_triggersStorageClear() {
        viewModel.clearAllTrips()
        XCTAssertTrue(mockTripService.didClearTrips)
    }
}
