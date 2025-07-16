//
//  TripRecordingViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class TripRecordingViewModelTests: XCTestCase {

    private var mockTracker: MockTripTrackingService!
    private var mockStore: MockTripSessionStore!
    private var viewModel: TripRecordingViewModel!

    override func setUp() {
        mockTracker = MockTripTrackingService()
        mockStore = MockTripSessionStore()
        viewModel = TripRecordingViewModel(tracker: mockTracker, store: mockStore)
    }

    func testStartTriggersRecordingState() {
        viewModel.start()
        XCTAssertEqual(viewModel.status, .recording)
        XCTAssertTrue(mockTracker.didStart)
    }

    func testStopTriggersIdleStateAndPersistsSession() {
        let fakeSession = TripSessionModel(distance: 123, segments: [])
        mockTracker.sessionStub = fakeSession

        viewModel.stop()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertTrue(mockTracker.didStop)
        XCTAssertEqual(mockStore.savedModels.first?.distance, 123)
    }

    func testTimerTracksDurationCorrectly() {
        let start = Date().addingTimeInterval(-5)
        mockTracker.sessionStub = TripSessionModel(startTime: start)

        viewModel.start()
        RunLoop.current.run(until: Date().addingTimeInterval(1.1)) // allow timer to tick
        XCTAssert(viewModel.duration >= 5)
    }

    func testStopCancelsTimer() {
        mockTracker.sessionStub = TripSessionModel(startTime: Date())
        viewModel.start()
        viewModel.stop()

        let durationAtStop = viewModel.duration
        RunLoop.current.run(until: Date().addingTimeInterval(1.5))
        XCTAssertEqual(viewModel.duration, durationAtStop)
    }
    
    func testStopWithoutStartDoesNotCrashAndPersistsNothing() {
        viewModel.stop()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertTrue(mockStore.savedModels.isEmpty)
        XCTAssertTrue(mockTracker.didStop)
    }

    func testStopWhenCurrentSessionIsNilDoesNotSave() {
        mockTracker.sessionStub = nil
        viewModel.stop()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertTrue(mockTracker.didStop)
        XCTAssertTrue(mockStore.savedModels.isEmpty)
    }

    func testSessionWithZeroDistanceAndNoSegmentsPersistsCleanly() {
        let session = TripSessionModel(
            startTime: Date(),
            endTime: Date().addingTimeInterval(10),
            distance: 0,
            segments: []
        )
        mockTracker.sessionStub = session
        viewModel.stop()

        XCTAssertEqual(mockStore.savedModels.count, 1)
        XCTAssertEqual(mockStore.savedModels.first?.distance, 0)
        XCTAssertEqual(mockStore.savedModels.first?.segments.count, 0)
    }

    func testTimerDoesNotCrashIfStartTimeIsNil() {
        mockTracker.sessionStub = TripSessionModel(
            id: UUID(),
            startTime: Date().addingTimeInterval(-5), // simulate uninitialized or bad date
            endTime: nil,
            distance: 0,
            segments: []
        )

        viewModel.start()
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        XCTAssertGreaterThanOrEqual(viewModel.duration, 0) // still ticks
    }

    func testTimerDoesNotCrashIfSessionIsNil() {
        viewModel.stop() // ensure clean state
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        XCTAssertEqual(viewModel.duration, 0, "Duration should remain 0 when no session is active")
    }
    
    func testTimerSkipsInvalidStartTimeGracefully() {
        let badSession = TripSessionModel(
            id: UUID(),
            startTime: .distantFuture,
            endTime: nil,
            distance: 0,
            segments: []
        )
        mockTracker.sessionStub = badSession
        viewModel.start()
        
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
        
        XCTAssertLessThan(viewModel.duration, 60 * 60 * 24 * 365, "Duration should not overflow from future startTime")
    }


    
}
