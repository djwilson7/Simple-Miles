//
//  TripRecordingViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class TripRecordingViewModelTests: XCTestCase {
    private var viewModel: TripRecordingViewModel!
    private var mockTracker: MockTripTrackingService!
    private var mockStore: MockTripSessionStore!

    override func setUp() {
        super.setUp()
        mockTracker = MockTripTrackingService()
        mockStore = MockTripSessionStore()
        viewModel = TripRecordingViewModel(tracker: mockTracker, store: mockStore)
    }

    override func tearDown() {
        viewModel = nil
        mockTracker = nil
        mockStore = nil
        super.tearDown()
    }

    func test_start_setsStatusAndStartsRecording() {
        viewModel.start()

        XCTAssertEqual(viewModel.status, .recording)
        XCTAssertTrue(mockTracker.didStartRecording)
    }

    func test_stop_setsStatusAndStopsRecording_andSavesTrip() {
        let session = MockTripSessionModel.make()
        mockTracker.currentSession = session

        viewModel.stop()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertTrue(mockTracker.didStopRecording)
        XCTAssertEqual(mockStore.mockTrips.first?.id, session.id)
    }

    func test_bind_updatesDistanceAndSegmentCount() {
        let segment1 = MockTripSegmentModel.make(distance: 100)
        let segment2 = MockTripSegmentModel.make(distance: 200)
        let session = MockTripSessionModel.make(distance: 300, segments: [segment1, segment2])

        mockTracker.currentSession = session
        mockTracker.publishSession(session)

        // Allow Combine pipeline to process
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        XCTAssertEqual(viewModel.distance, 300)
        XCTAssertEqual(viewModel.segmentCount, 2)
    }


    func test_startTimer_and_stopTimer_updatesDuration() {
        let startTime = Date().addingTimeInterval(-120)
        let session = MockTripSessionModel.make(startTime: startTime)
        mockTracker.currentSession = session

        viewModel.start()
        RunLoop.main.run(until: Date().addingTimeInterval(1.5))
        viewModel.stop()

        XCTAssertGreaterThanOrEqual(viewModel.duration, 120)
    }
}
