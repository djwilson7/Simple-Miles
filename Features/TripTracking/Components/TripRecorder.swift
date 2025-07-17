//
//  TripRecorder.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation

final class TripRecorder {
    let trackingService: TripTrackingService
    let state: any TripRecordingStateProtocol

    private var stopGraceTimer: Timer?
    private var pausedSession: TripSessionModel?
    private var pauseTime: Date?

    static let shared: TripRecorder = {
        let sharedState = TripTrackingService.shared.recordingState
        return TripRecorder(
            trackingService: TripTrackingService.shared,
            state: sharedState
        )
    }()

    init(
        trackingService: TripTrackingService,
        state: any TripRecordingStateProtocol
    ) {
        self.trackingService = trackingService
        self.state = state
    }

    func startTrip() {
        print("[TripRecorder] startTrip called")
        stopGraceTimer?.invalidate()
        pausedSession = nil
        pauseTime = nil

        trackingService.startRecording()
        print("[TripRecorder] trackingService.startRecording triggered")

        state.isRecording = true
        state.session = trackingService.currentSession
        state.startTimer()
        print("[TripRecorder] session started with ID: \(state.session?.id.uuidString ?? "nil")")
    }

    func pauseTrip() {
        guard state.isRecording else {
            print("[TripRecorder] pauseTrip ignored — not recording")
            return
        }

        print("[TripRecorder] pauseTrip called")
        pausedSession = trackingService.currentSession
        pauseTime = Date()

        trackingService.stopRecording()
        state.isRecording = false
        state.stopTimer()
        stopGraceTimer?.invalidate()
        print("[TripRecorder] trip paused at \(pauseTime!)")
    }

    func resumeTripIfNeeded() -> Bool {
        guard let paused = pausedSession, let pausedAt = pauseTime else {
            print("[TripRecorder] resumeTripIfNeeded — no paused session")
            return false
        }

        let now = Date()
        let resumeWindow: TimeInterval = 600

        guard now.timeIntervalSince(pausedAt) <= resumeWindow else {
            print("[Resume] Expired pause window — resume blocked")
            return false
        }

        print("[TripRecorder] Resuming trip from paused state")
        trackingService.resumeRecording(from: paused)
        state.isRecording = true
        state.session = paused
        state.startTimer()
        pausedSession = nil
        pauseTime = nil
        print("[TripRecorder] Trip resumed successfully")
        return true
    }

    func stopTrip() {
        guard state.isRecording else {
            print("[TripRecorder] stopTrip ignored — not recording")
            return
        }

        print("[TripRecorder] stopTrip called")
        trackingService.stopRecording()
        state.isRecording = false
        state.stopTimer()
        state.resetPauseCountdown(duration: 0)
        state.update(with: trackingService.currentSession)
        stopGraceTimer?.invalidate()
        print("[TripRecorder] Trip stopped and session saved")
    }
}
