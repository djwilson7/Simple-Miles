//
//  TripRecorderEdgeCaseTests.swift
//  SimpleMilesTests
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
import Combine
@testable import SimpleMiles

final class TripRecorderEdgeCaseTests: XCTestCase {
    
    var recorder: TripRecorder!
    var cancellables: Set<AnyCancellable> = []
    var mockRecordingStates: [Bool] = []
    var mockSessions: [TripSession?] = []

    override func setUpWithError() throws {
        recorder = TripRecorder()
        
        // Observe recording state transitions
        recorder.state.$isRecording
            .dropFirst() //ignore the initall 'false'
            .sink { [weak self] isRecording in
                self?.mockRecordingStates.append(isRecording)
            }
            .store(in: &cancellables)

        // Observe session snapshots
        recorder.state.$session
            .sink { [weak self] session in
                self?.mockSessions.append(session)
            }
            .store(in: &cancellables)
    }

    override func tearDownWithError() throws {
        recorder = nil
        cancellables.removeAll()
        mockRecordingStates.removeAll()
        mockSessions.removeAll()
    }
    
    func testStartTripSetsRecordingStateToTrue() {
        recorder.startTrip()

        XCTAssertTrue(recorder.state.isRecording, "Recording state should be true after starting a trip")
        XCTAssertEqual(mockRecordingStates.last, true, "Last recorded state should be true after startTrip()")
    }

    func testStopTripSetsRecordingStateToFalse() {
        recorder.startTrip()
        recorder.stopTrip()

        XCTAssertFalse(recorder.state.isRecording, "Recording state should be false after stopping a trip")
        XCTAssertEqual(mockRecordingStates.last, false, "Last recorded state should be false after stopTrip()")
    }

    func testResetClearsState() {
        recorder.startTrip()
        recorder.reset()

        XCTAssertFalse(recorder.state.isRecording, "Recording state should be false after reset")
        XCTAssertNil(recorder.state.session, "Session should be nil after reset")
    }
    
    // MARK: - Lifecycle Edge Cases

    func testStartTripMultipleTimesDoesNotDuplicateState() {
        recorder.startTrip()
        recorder.startTrip()
        
        XCTAssertTrue(recorder.state.isRecording)
        XCTAssertEqual(mockRecordingStates.filter { $0 == true }.count, 1, "Should only transition to true once")
    }

    func testStopTripWithoutStartDoesNotCrashOrRecord() {
        recorder.stopTrip()
        
        XCTAssertFalse(recorder.state.isRecording)
        XCTAssertNil(recorder.state.session)
    }

    func testResetDuringRecordingStopsTimerAndClearsSession() {
        recorder.startTrip()
        recorder.reset()
        
        XCTAssertFalse(recorder.state.isRecording)
        XCTAssertNil(recorder.state.session)
        XCTAssertEqual(mockRecordingStates.last, false)
    }

    func testResetAfterStopTripClearsSession() {
        recorder.startTrip()
        recorder.stopTrip()
        recorder.reset()

        XCTAssertFalse(recorder.state.isRecording)
        XCTAssertNil(recorder.state.session)
    }
    
    func testStartTripMultipleTimesDoesNotBreakState() {
        recorder.startTrip()
        recorder.startTrip()  // should be idempotent

        XCTAssertTrue(recorder.state.isRecording)
        XCTAssertEqual(mockRecordingStates.filter { $0 == true }.count, 1, "Only one transition to true should occur")
    }

    func testStopTripWithoutStartDoesNothing() {
        recorder.stopTrip()

        XCTAssertFalse(recorder.state.isRecording)
        XCTAssertNil(recorder.state.session, "Session should remain nil when stopTrip is called without starting")
    }

    func testResetWithoutStartIsSafe() {
        recorder.reset()

        XCTAssertFalse(recorder.state.isRecording)
        XCTAssertNil(recorder.state.session)
    }

    func testStopTripPreservesOriginalStartTime() {
        recorder.startTrip()
        let startTime = recorder.state.session?.startTime
        sleep(1)
        recorder.stopTrip()

        XCTAssertEqual(recorder.state.session?.startTime, startTime, "Start time should remain unchanged after stop")
        XCTAssertNotNil(recorder.state.session?.endTime)
    }

    func testTripDurationIsGreaterThanZero() {
        recorder.startTrip()
        sleep(1)
        recorder.stopTrip()

        guard let start = recorder.state.session?.startTime,
              let end = recorder.state.session?.endTime else {
            XCTFail("Start and end time should be present")
            return
        }

        XCTAssertGreaterThan(end.timeIntervalSince(start), 0, "Trip duration should be greater than zero")
    }

    func testResetAfterStopClearsEndTime() {
        recorder.startTrip()
        sleep(1)
        recorder.stopTrip()
        recorder.reset()

        XCTAssertNil(recorder.state.session)
    }

    func testStartAfterResetCreatesFreshSession() {
        recorder.startTrip()
        recorder.stopTrip()
        recorder.reset()

        recorder.startTrip()
        XCTAssertNotNil(recorder.state.session)
        XCTAssertNil(recorder.state.session?.endTime)
    }
    // MARK: - Session & Timer Integration

    func testSessionUpdatesAfterStopTrip() {
        recorder.startTrip()
        recorder.stopTrip()
        
        guard let session = recorder.state.session else {
            XCTFail("Session should not be nil after stopTrip()")
            return
        }

        XCTAssertNotNil(session.startTime)
        XCTAssertNotNil(session.endTime)
    }

    func testTimerDoesNotStartWhenTripNotStarted() {
        XCTAssertFalse(recorder.state.isRecording)
        XCTAssertNil(recorder.state.debugTimer)
    }

    // MARK: - Publisher Integrity

    func testPublisherEmitsProperSequence() {
        recorder.startTrip()
        recorder.stopTrip()
        
        XCTAssertEqual(mockRecordingStates, [true, false])
        XCTAssertGreaterThanOrEqual(mockSessions.count, 2)
    }

    // MARK: - Invalid Usage Protection

    func testStartStopStartSequenceBehavesCorrectly() {
        recorder.startTrip()
        recorder.stopTrip()
        recorder.startTrip()

        XCTAssertTrue(recorder.state.isRecording)
        XCTAssertNotNil(recorder.state.session)
        XCTAssertEqual(mockRecordingStates.filter { $0 == true }.count, 2)
    }

    func testMultipleStopsOnlyTriggersOneStateTransition() {
        recorder.startTrip()
        recorder.stopTrip()
        recorder.stopTrip()
        recorder.stopTrip()
        
        XCTAssertEqual(mockRecordingStates.filter { $0 == false }.count, 1, "Should only emit one false transition")
    }
}
