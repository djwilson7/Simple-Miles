//
//  MockTripTrackingService.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Combine
@testable import SimpleMiles

final class MockTripTrackingService: TripTrackingServiceProtocol {
    @Published var currentSession: TripSessionModel?
    var currentSessionPublisher: Published<TripSessionModel?>.Publisher { $currentSession }

    var recordingState: any TripRecordingStateProtocol = MockTripRecordingState()
    var onTripSaved: (() -> Void)?

    private(set) var didStartRecording = false
    private(set) var didStopRecording = false
    private(set) var didClearTrips = false
    private(set) var didStartPassiveMonitoring = false
    private(set) var receivedThresholds: (speed: Double, distance: Double)?
    private(set) var resumedSession: TripSessionModel?

    func startRecording() {
        didStartRecording = true
    }

    func stopRecording() {
        didStopRecording = true
    }

    func clearAllTrips() {
        didClearTrips = true
    }

    func startPassiveMonitoring() {
        didStartPassiveMonitoring = true
    }

    func updateAnalyzerThresholds(speed: Double, distance: Double) {
        receivedThresholds = (speed, distance)
    }

    func resumeRecording(from session: TripSessionModel) {
        resumedSession = session
    }

    func publishSession(_ session: TripSessionModel) {
        currentSession = session
    }
}
