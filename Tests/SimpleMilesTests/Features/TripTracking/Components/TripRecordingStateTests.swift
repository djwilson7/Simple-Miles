//
//  TripRecordingStateTests.swift
//  SimpleMilesTests
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
@testable import SimpleMiles

final class TripRecordingStateTests: XCTestCase {

    var state: TripRecordingState!

    override func setUpWithError() throws {
        state = TripRecordingState()
    }

    override func tearDownWithError() throws {
        state = nil
    }

    // MARK: - Initial State

    func testInitialStateIsCorrect() {
        XCTAssertFalse(state.isRecording)
        XCTAssertNil(state.session)
        XCTAssertNil(state.debugTimer)
    }

    // MARK: - Timer Behavior

    func testStartTimerCreatesTimer() {
        state.startTimer()
        XCTAssertNotNil(state.debugTimer, "Timer should be created after calling startTimer")
    }

    func testStopTimerInvalidatesAndClearsTimer() {
        state.startTimer()
        state.stopTimer()
        XCTAssertNil(state.debugTimer, "Timer should be nil after stopTimer is called")
    }

    func testStopTimerDoesNothingWhenNoTimerExists() {
        XCTAssertNoThrow(state.stopTimer(), "Calling stopTimer with no active timer should not crash")
    }

    // MARK: - Reset Behavior

    func testResetClearsAllValues() {
        state.isRecording = true
        state.session = TripSessionModel()
        state.startTimer()

        state.reset()

        XCTAssertFalse(state.isRecording, "isRecording should be false after reset")
        XCTAssertNil(state.session, "session should be nil after reset")
        XCTAssertNil(state.debugTimer, "Timer should be nil after reset")
    }

    // MARK: - Update Integration

    func testUpdateReplacesCurrentSession() {
        let original = TripSessionModel(startTime: Date(), endTime: Date().addingTimeInterval(10))

        state.update(with: original)

        XCTAssertEqual(state.session?.startTime, original.startTime)
        XCTAssertEqual(state.session?.endTime, original.endTime)
    }
}
