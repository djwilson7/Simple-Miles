//  TripRecordingViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: start/stop status and service calls, session save on stop, path-based distance and count updates, timer-driven duration,
//  and Combine-driven session binding logic. Suite ensures correct propagation of all core properties and interaction flows
//  under all relevant state changes, using the path-based session model.

import XCTest
@testable import SimpleMiles

final class TripRecordingViewModelTests: XCTestCase {
    private var viewModel: TripRecordingViewModel!
    private var mockTracker: MockTripTrackingService!
    private var mockStore: MockTripPersistenceManager!

    override func setUp() async throws {
        try await super.setUp()
        mockTracker = MockTripTrackingService()
        mockStore = MockTripPersistenceManager()
        viewModel = await TripRecordingViewModel(tracker: mockTracker, store: mockStore)
    }

    override func tearDown() async throws {
        viewModel = nil
        mockTracker = nil
        mockStore = nil
        try await super.tearDown()
    }

    func test_start_setsStatusAndStartsRecording() async {
        await viewModel.start()
        await MainActor.run {
            XCTAssertEqual(viewModel.status, .recording)
        }
        XCTAssertTrue(mockTracker.didStartRecording)
    }

    func test_stop_setsStatusAndStopsRecording_andSavesTrip() async {
        let path = [CoordinateModel(latitude: 5, longitude: 5), CoordinateModel(latitude: 6, longitude: 6)]
        let session = MockTripSessionModel.make(path: path)
        mockTracker.currentSession = session

        await viewModel.stop()

        await MainActor.run {
            XCTAssertEqual(viewModel.status, .idle)
        }
        XCTAssertTrue(mockTracker.didStopRecording)
        XCTAssertTrue(mockStore.didSave)
        XCTAssertEqual(mockStore.savedTrip?.id, session.id)
        XCTAssertEqual(mockStore.savedTrip?.path, path)
    }

    func test_bind_updatesDistanceAndPathPointCount() async {
        let path = [
            CoordinateModel(latitude: 1, longitude: 2),
            CoordinateModel(latitude: 2, longitude: 3),
            CoordinateModel(latitude: 3, longitude: 4)
        ]
        let session = MockTripSessionModel.make(distance: 1200, path: path)
        mockTracker.currentSession = session
        mockTracker.publishSession(session)

        try? await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            XCTAssertEqual(viewModel.distance, 1200)
            XCTAssertEqual(viewModel.pathPointCount, path.count)
        }
    }

    func test_startTimer_and_stopTimer_updatesDuration() async {
        let startTime = Date().addingTimeInterval(-120)
        let session = MockTripSessionModel.make(startTime: startTime)
        mockTracker.currentSession = session

        await viewModel.start()
        try? await Task.sleep(nanoseconds: 1_200_000_000)
        await viewModel.stop()

        await MainActor.run {
            XCTAssertGreaterThanOrEqual(viewModel.duration, 120)
        }
    }

    func test_bind_withNilSession_setsDistanceAndPathToZero() async {
        mockTracker.currentSession = nil
        mockTracker.publishSession(nil)
        try? await Task.sleep(nanoseconds: 50_000_000)

        await MainActor.run {
            XCTAssertEqual(viewModel.distance, 0)
            XCTAssertEqual(viewModel.pathPointCount, 0)
        }
    }

    func test_stop_withoutCurrentSession_doesNotSave() async {
        await viewModel.stop()
        XCTAssertFalse(mockStore.didSave)
        XCTAssertNil(mockStore.savedTrip)
    }
}
