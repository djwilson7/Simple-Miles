import Foundation

final class TripRecordingState: TripRecordingStateProtocol, ObservableObject {
    @Published var isRecording: Bool = false
    @Published var isPaused: Bool = false

    @Published var session: TripSessionModel?
    @Published var elapsedTime: TimeInterval = 0
    @Published var loggedTripCoords: Int = 0
    @Published var totalDistance: Double = 0.0
    @Published var pauseExpiresAt: Date?
    @Published var remainingPauseTime: TimeInterval = 0

    private var pauseCountdownTimer: Timer?
    private var timer: Timer?

    var onPauseTimeout: (() -> Void)?

    #if DEBUG
    var debugTimer: Timer? {
        return timer
    }
    #endif

    func update(with session: TripSessionModel?) {
        DispatchQueue.main.async {
            self.session = session
            self.isRecording = session != nil
            self.loggedTripCoords = session?.path.count ?? 0
            self.totalDistance = session?.distance ?? 0.0

            if let start = session?.startTime, let end = session?.endTime {
                self.elapsedTime = end.timeIntervalSince(start)
            } else if let start = session?.startTime {
                self.elapsedTime = Date().timeIntervalSince(start)
            } else {
                self.elapsedTime = 0
            }
        }
    }

    func reset() {
        DispatchQueue.main.async {
            self.isRecording = false
            self.session = nil
            self.elapsedTime = 0
            self.loggedTripCoords = 0
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
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func startPauseCountdown(duration: TimeInterval = 600) {
        DispatchQueue.main.async {
            print("[TripRecordingState] pause triggered, setting isPaused = true")
            self.pauseExpiresAt = Date().addingTimeInterval(duration)
            self.isPaused = true
        }
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
        DispatchQueue.main.async {
            self.pauseExpiresAt = nil
            self.remainingPauseTime = 0
            self.isPaused = false
        }
    }

    func setRecording(_ active: Bool) {
        DispatchQueue.main.async {
            self.isRecording = active
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
            onPauseTimeout?()
        }
    }

    var publisherValues: TripRecordingStatePublishers {
        .init(
            isRecording: $isRecording,
            totalDistance: $totalDistance,
            loggedTripCoords: $loggedTripCoords,
            elapsedTime: $elapsedTime,
            remainingPauseTime: $remainingPauseTime,
            isPaused: $isPaused
        )
    }
}
