//
//  TripRecordingState.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/13/25.
//

// TripRecordingState.swift
import Foundation

final class TripRecordingState: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var session: TripSessionModel?
    @Published var elapsedTime: TimeInterval = 0
    @Published var segmentCount: Int = 0
    @Published var totalDistance: Double = 0.0
    @Published var pauseExpiresAt: Date?
    @Published var remainingPauseTime: TimeInterval = 0
    
    var isPaused: Bool {
        return pauseExpiresAt != nil
    }
    
    private var pauseCountdownTimer: Timer?
    private var timer: Timer?

    #if DEBUG
    var debugTimer: Timer? {
        return timer
    }
    #endif
    
    func update(with session: TripSessionModel?) {
        DispatchQueue.main.async {
            self.session = session
            self.segmentCount = session?.segments.count ?? 0
            self.totalDistance = session?.distance ?? 0.0

            if let start = session?.startTime, let end = session?.endTime {
                self.elapsedTime = end.timeIntervalSince(start)
            } else if let start = session?.startTime {
                self.elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.isRecording = false
            self.session = nil
            self.elapsedTime = 0
            self.segmentCount = 0
            self.totalDistance = 0
        }
        timer?.invalidate()
        timer = nil
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let start = self.session?.startTime else { return }
            let elapsed = Date().timeIntervalSince(start)
            DispatchQueue.main.async {
                self.elapsedTime = elapsed
                print("[State] elapsedTime updated: \(self.elapsedTime)")

            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func startPauseCountdown(duration: TimeInterval = 600) {
        pauseExpiresAt = Date().addingTimeInterval(duration)
        updatePauseTime()

        pauseCountdownTimer?.invalidate()
        pauseCountdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePauseTime()
        }
    }

    func resetPauseCountdown(duration: TimeInterval = 600) {
        startPauseCountdown(duration: duration)
    }

    func cancelPauseCountdown() {
        pauseCountdownTimer?.invalidate()
        pauseCountdownTimer = nil
        pauseExpiresAt = nil
        DispatchQueue.main.async {
            self.remainingPauseTime = 0
        }
    }

    private func updatePauseTime() {
        guard let expiresAt = pauseExpiresAt else { return }
        let now = Date()
        let remaining = expiresAt.timeIntervalSince(now)
        DispatchQueue.main.async {
            self.remainingPauseTime = max(0, remaining)
        }

        if remaining <= 0 {
            cancelPauseCountdown()
            TripRecorder.shared.stopTrip()
        }
    }
}
