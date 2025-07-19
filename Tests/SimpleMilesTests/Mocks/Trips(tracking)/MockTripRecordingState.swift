//  MockTripRecordingState.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Fully conforms to TripRecordingStateProtocol for path-based trip, using published isPaused property for Combine compatibility.

import Foundation
import Combine
@testable import SimpleMiles

final class MockTripRecordingState: TripRecordingStateProtocol {
    @Published var isRecording: Bool = false
    @Published var session: TripSessionModel?
    @Published var elapsedTime: TimeInterval = 0
    @Published var loggedTripCoords: Int = 0
    @Published var totalDistance: Double = 0.0
    @Published var pauseExpiresAt: Date? {
        didSet { isPaused = pauseExpiresAt != nil }
    }
    @Published var remainingPauseTime: TimeInterval = 0
    @Published var isPaused: Bool = false

    private(set) var didResetPause = false
    private(set) var didReset = false

    lazy var publisherValues: TripRecordingStatePublishers = {
        .init(
            isRecording: $isRecording,
            totalDistance: $totalDistance,
            loggedTripCoords: $loggedTripCoords,
            elapsedTime: $elapsedTime,
            remainingPauseTime: $remainingPauseTime,
            isPaused: $isPaused
        )
    }()

    func update(with session: TripSessionModel?) {}
    func reset() { didReset = true }
    func startTimer() {}
    func stopTimer() {}
    func startPauseCountdown(duration: TimeInterval) {}
    func resetPauseCountdown(duration: TimeInterval = 600) { didResetPause = true }
    func cancelPauseCountdown() {}
    func setRecording(_ active: Bool) { isRecording = active }
}

