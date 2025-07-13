//
//  TripRecorder.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation

final class TripRecorder {
    let trackingService: TripTrackingService
    let state: TripRecordingState

    init(trackingService: TripTrackingService = TripTrackingService(), state: TripRecordingState = TripRecordingState()) {
        self.trackingService = trackingService
        self.state = state
    }

    func startTrip() {
        guard !state.isRecording else { return }
        
        trackingService.startRecording()
        state.isRecording = true
        state.session = trackingService.currentSession
        state.startTimer()
    }

    func stopTrip() {
        guard state.isRecording else { return }
        
        trackingService.stopRecording()
        state.isRecording = false
        state.stopTimer()
        state.update(with: trackingService.currentSession)
    }

    func reset() {
        state.reset()
    }
}
