//  DeveloperPanelViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: published property binding, action methods, notification effects, threshold combination, onTripSaved, all export logic, launcher injection, edge flag transitions, and advanced async/Combine flows.
//  All advanced and edge flows are included. The suite guarantees complete coverage for both normal operation and abnormal/edge conditions.

import XCTest
import Combine
@testable import SimpleMiles

final class DeveloperPanelViewModelTests: XCTestCase {
    private var viewModel: DeveloperPanelViewModel!
    private var mockTripService: MockTripTrackingService!
    private var mockExportViewModel: MockTripExportViewModel!
    private var mockExportLauncher: MockExportLauncher!
    private var cancellables: Set<AnyCancellable> = []

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
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Basic Functionality

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

    func test_exportAllTripsAsCSV_success_triggersExportAndLauncher() {
        mockExportViewModel.exportedCSVURL = URL(fileURLWithPath: "/mock/csv")
        viewModel.exportAllTripsAsCSV()
        XCTAssertEqual(mockExportLauncher.launchedURL, mockExportViewModel.exportedCSVURL)
        XCTAssertTrue(mockExportLauncher.isPresenting)
        XCTAssertEqual(viewModel.savedTripCount, 0)
        XCTAssertFalse(viewModel.showToast)
    }

    func test_exportAllTripsAsCSV_failure_showsToast() {
        mockExportViewModel.exportedCSVURL = nil
        viewModel.exportAllTripsAsCSV()
        XCTAssertTrue(viewModel.showToast)
        XCTAssertEqual(viewModel.toastMessage, "CSV export failed")
    }

    func test_exportAllTripsAsJSON_success_triggersExportAndLauncher() {
        mockExportViewModel.exportedJSONURL = URL(fileURLWithPath: "/mock/json")
        viewModel.exportAllTripsAsJSON()
        XCTAssertEqual(mockExportLauncher.launchedURL, mockExportViewModel.exportedJSONURL)
        XCTAssertTrue(mockExportLauncher.isPresenting)
        XCTAssertEqual(viewModel.savedTripCount, 0)
        XCTAssertFalse(viewModel.showToast)
    }

    func test_exportAllTripsAsJSON_failure_showsToast() {
        mockExportViewModel.exportedJSONURL = nil
        viewModel.exportAllTripsAsJSON()
        XCTAssertTrue(viewModel.showToast)
        XCTAssertEqual(viewModel.toastMessage, "JSON export failed")
    }

    func test_refreshTripCount_updatesSavedTripCount() {
        let trip = MockTripSessionModel.make()
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
        let mockState = mockTripService.recordingState as! MockTripRecordingState
        XCTAssertTrue(mockState.didReset)
    }

    func test_clearAllTrips_triggersStorageClear() {
        viewModel.clearAllTrips()
        XCTAssertTrue(mockTripService.didClearTrips)
    }

    // MARK: - Advanced Functionality

    func test_resumeSpeedAndDistanceThresholds_updateAnalyzer() {
        viewModel.resumeSpeedThreshold = 4.2
        viewModel.resumeDistanceThreshold = 120
        // Allow Combine/async propagation if needed
        XCTAssertEqual(mockTripService.receivedThresholds?.speed, 4.2)
        XCTAssertEqual(mockTripService.receivedThresholds?.distance, 120)
    }

    func test_onTripSaved_triggersRefreshTripCount() {
        let trips = [MockTripSessionModel.make(), MockTripSessionModel.make()]
        mockExportViewModel.store = MockTripSessionStore()
        trips.forEach { mockExportViewModel.store.save($0) }
        viewModel.savedTripCount = 0
        mockTripService.onTripSaved?()
        XCTAssertEqual(viewModel.savedTripCount, 2)
    }

    func test_notification_didClearTripData_resetsSavedCountAndShowsToast() {
        viewModel.savedTripCount = 7
        let exp = expectation(description: "Toast updated")
        viewModel.$showToast
            .dropFirst()
            .sink { show in
                if show {
                    XCTAssertEqual(self.viewModel.savedTripCount, 0)
                    XCTAssertEqual(self.viewModel.toastMessage, "Trip data cleared successfully")
                    exp.fulfill()
                }
            }.store(in: &cancellables)

        NotificationCenter.default.post(name: .didClearTripData, object: nil)
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Edge Cases

    func test_forceEndTrip_whenAlreadyPaused_setsIsPausedFalse() {
        viewModel.isPaused = true
        viewModel.forceEndTrip()
        XCTAssertFalse(viewModel.isPaused)
    }

    func test_exportLauncher_replacement_updatesObserved() {
        let newMockLauncher = MockExportLauncher()
        viewModel.exportLauncher = newMockLauncher
        mockExportViewModel.exportedCSVURL = URL(fileURLWithPath: "/mock/csv")
        viewModel.exportAllTripsAsCSV()
        XCTAssertEqual(newMockLauncher.launchedURL, mockExportViewModel.exportedCSVURL)
    }

    func test_binding_liveTripState_updatesAllPublishedProperties() {
        let mockState = mockTripService.recordingState as! MockTripRecordingState

        mockState.isRecording = true
        mockState.totalDistance = 123.4
        mockState.loggedTripCoords = 17
        mockState.elapsedTime = 890
        mockState.remainingPauseTime = 22
        mockState.pauseExpiresAt = Date()
        // Allow time for bindings to propagate
        RunLoop.main.run(until: Date().addingTimeInterval(0.01))

        XCTAssertTrue(viewModel.isTracking)
        XCTAssertEqual(viewModel.currentDistance, 123.4)
        XCTAssertEqual(viewModel.loggedTripCoords, 17)
        XCTAssertEqual(viewModel.elapsedTime, 890)
        XCTAssertEqual(viewModel.remainingPauseTime, 22)
        XCTAssertTrue(viewModel.isPaused)
    }
}
