//
//  TripLifecycleManagerTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
@testable import SimpleMiles

final class TripLifecycleManagerTests: XCTestCase {
    private var manager: TripLifecycleManager!

    override func setUp() {
        manager = TripLifecycleManager()
    }

    func test_startSession_initializesNewSession() {
        manager.startSession()
        let session = manager.currentSession
        XCTAssertNotNil(session)
        XCTAssertNotNil(session?.startTime)
        XCTAssertNil(session?.endTime)
        XCTAssertEqual(session?.segments.count, 0)
    }

    func test_stopSession_setsEndTime() {
        manager.startSession()
        manager.stopSession()

        let session = manager.currentSession
        XCTAssertNotNil(session?.endTime)
        XCTAssertTrue((session?.endTime ?? Date()) >= session?.startTime ?? Date())
    }

    func test_resumeSession_setsCurrentSession() {
        let existing = MockTripSessionModel.make()
        manager.resumeSession(from: existing)

        XCTAssertEqual(manager.currentSession?.id, existing.id)
    }
}
