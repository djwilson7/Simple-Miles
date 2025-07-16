//
//  TripRecorderEdgeCaseTests.swift
//  SimpleMilesTests
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
import Combine
import CoreLocation
@testable import SimpleMiles

final class TripRecorderEdgeCaseTests: XCTestCase {
    
    var recorder: TripRecorder!
    var mockTrackingService: MockTripTrackingService!
    var state: TripRecordingState!
    var cancellables: Set<AnyCancellable> = []
    var mockRecordingStates: [Bool] = []
    var mockSessions: [TripSessionModel?] = []

    override func setUpWithError() throws {
        mockTrackingService = MockTripTrackingService()
        state = TripRecordingState()
        recorder = TripRecorder(trackingService: mockTrackingService, state: state)
        
        recorder.state.$isRecording
            .dropFirst()
            .sink { [weak self] isRecording in
                self?.mockRecordingStates.append(isRecording)
            }
            .store(in: &cancellables)

        recorder.state.$session
            .sink { [weak self] session in
                self?.mockSessions.append(session)
            }
            .store(in: &cancellables)
    }

    override func tearDownWithError() throws {
        recorder = nil
        mockTrackingService = nil
        state = nil
        cancellables.removeAll()
        mockRecordingStates.removeAll()
        mockSessions.removeAll()
    }

    func testStartTripCallsTrackingServiceAndUpdatesState() {
        recorder.startTrip()

        XCTAssertTrue(mockTrackingService.didStartRecording)
        XCTAssertTrue(state.isRecording)
        XCTAssertEqual(mockRecordingStates.last, true)
    }

    func testStopTripCallsTrackingServiceAndUpdatesState() {
        recorder.startTrip()
        recorder.stopTrip()

        XCTAssertTrue(mockTrackingService.didStopRecording)
        XCTAssertFalse(state.isRecording)
        XCTAssertEqual(mockRecordingStates.last, false)
    }

    func testPauseTripStopsRecordingAndPreservesState() {
        recorder.startTrip()
        recorder.pauseTrip()

        XCTAssertTrue(mockTrackingService.didStopRecording)
        XCTAssertFalse(state.isRecording)
        XCTAssertNotNil(state.session)
        XCTAssertNotNil(state.debugTimer)
    }

    func testResumeTripIfWithinWindowRestoresSession() {
        recorder.startTrip()
        recorder.pauseTrip()

        let resumed = recorder.resumeTripIfNeeded()
        XCTAssertTrue(resumed)
        XCTAssertTrue(state.isRecording)
        XCTAssertEqual(state.session?.id, mockTrackingService.mockSession.id)
    }

    func testResumeTripFailsIfOutsideWindow() {
        recorder.startTrip()
        recorder.pauseTrip()

        // Simulate expired resume window
        recorder.pauseTime = Date(timeIntervalSinceNow: -601)

        let resumed = recorder.resumeTripIfNeeded()
        XCTAssertFalse(resumed)
        XCTAssertFalse(state.isRecording)
    }

    func testResetClearsSessionAndState() {
        recorder.startTrip()
        recorder.stopTrip()
        recorder.reset()

        XCTAssertFalse(state.isRecording)
        XCTAssertNil(state.session)
    }
}
