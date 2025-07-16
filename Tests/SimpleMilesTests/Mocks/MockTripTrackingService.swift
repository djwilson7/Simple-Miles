//
//  MockTripTrackingService.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import CoreLocation
@testable import SimpleMiles

final class MockTripTrackingService: TripTrackingServiceProtocol {
    var didStart = false
    var didStop = false
    var didResume = false
    var resumeCalledWith: TripSessionModel?
    
    var sessionStub: TripSessionModel = TripSessionModel()

    var currentSession: TripSessionModel? {
        return sessionStub
    }

    func startRecording() {
        didStart = true
    }

    func stopRecording() {
        didStop = true
    }

    func resumeRecording(from session: TripSessionModel) {
        didResume = true
        resumeCalledWith = session
        sessionStub = session
    }
}
