//
//  MockTripRecordingState.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockTripRecordingState: TripRecordingStateProtocol {
    @Published var isRecording: Bool = false
    @Published var session: TripSessionModel?
    @Published var elapsedTime: TimeInterval = 0
    @Published var segmentCount: Int = 0
    @Published var totalDistance: Double = 0.0
    @Published var pauseExpiresAt: Date?
    @Published var remainingPauseTime: TimeInterval = 0

    var isPaused: Bool { pauseExpiresAt != nil }
    private(set) var didResetPause = false

    var publisherValues: TripRecordingStatePublishers {
        .init(
            isRecording: $isRecording,
            totalDistance: $totalDistance,
            segmentCount: $segmentCount,
            elapsedTime: $elapsedTime,
            remainingPauseTime: $remainingPauseTime,
            pauseExpiresAt: $pauseExpiresAt
        )
    }

    func update(with session: TripSessionModel?) {}
    func reset() {}
    func startTimer() {}
    func stopTimer() {}
    func startPauseCountdown(duration: TimeInterval) {}
    func resetPauseCountdown(duration: TimeInterval = 600) { didResetPause = true }
    func cancelPauseCountdown() {}
}

