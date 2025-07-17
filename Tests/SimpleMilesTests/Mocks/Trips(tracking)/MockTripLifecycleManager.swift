//
//  MockTripLifecycleManager.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockTripLifecycleManager: TripLifecycleManagingProtocol {
    private(set) var didStartSession = false
    private(set) var didStopSession = false
    private(set) var resumedSession: TripSessionModel?

    var mockSession: TripSessionModel? = MockTripSessionModel.make()
    var currentSession: TripSessionModel? {
        mockSession
    }

    func startSession() {
        didStartSession = true
    }

    func stopSession() {
        didStopSession = true
    }

    func resumeSession(from session: TripSessionModel) {
        resumedSession = session
        mockSession = session
    }
}
