import Foundation
import Combine
import CoreLocation

final class MovementMonitor: MovementMonitoringProtocol {
    private var analyzer: MovementAnalyzerProtocol
    private var accelCancellable: AnyCancellable?
    private var speedCancellable: AnyCancellable?

    var onShouldStartTrip: (() -> Void)?
    var onShouldPauseTrip: (() -> Void)?
    var onShouldResumeTrip: (() -> Void)?
    var onShouldStopTrip: (() -> Void)?

    private var state: MotionState = .idle
    private var sessionStartTime: Date?
    private var lastMotionTimestamp: Date?
    private var lastIdleTimestamp: Date?
    private var pauseCandidateStart: Date?

    private var accelBuffer: [Double] = []
    private var speedBuffer: [CLLocationSpeed] = []
    private var lastKnownLocation: CLLocation?
    private let bufferLimit: Int = 10  // 10s at 1Hz

    init(analyzer: MovementAnalyzerProtocol) {
        self.analyzer = analyzer
        bindMotionStream()
        bindSpeedStream()
    }

    func startPassiveMonitoring() {
        resetState()
    }
    
    func updateLastLocation(_ location: CLLocation) {
        lastKnownLocation = location
    }

    func resetState() {
        state = .idle
        sessionStartTime = nil
        lastMotionTimestamp = nil
        lastIdleTimestamp = nil
        pauseCandidateStart = nil
        accelBuffer.removeAll()
        speedBuffer.removeAll()
        lastKnownLocation = nil
    }

    func analyze(location: CLLocation) {
        lastKnownLocation = location
    }

    func updateThresholds(speed: CLLocationSpeed, distance: CLLocationDistance) {
        // no-op in hybrid model
    }

    private func bindMotionStream() {
        accelCancellable = MotionService.shared.accelerationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sample in
                guard let self else { return }
                accelBuffer.append(sample.value)
                if accelBuffer.count > bufferLimit { accelBuffer.removeFirst() }
                evaluateMotion()
            }
    }

    private func bindSpeedStream() {
        speedCancellable = LocationService.shared.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                lastKnownLocation = location
                speedBuffer.append(location.speed)
                if speedBuffer.count > bufferLimit { speedBuffer.removeFirst() }
            }
    }

    private func evaluateMotion() {
        let now = Date()

        switch state {
        case .idle:
            if analyzer.shouldPreemptivelyMonitor(accelerations: accelBuffer) {
                state = .primed
                print("[MovementMonitor] transition: idle -> primed")
            }

        case .primed:
            if analyzer.shouldStartRecording(speeds: speedBuffer, accelerations: accelBuffer) {
                state = .active
                sessionStartTime = now
                lastMotionTimestamp = now
                print("[MovementMonitor] trip started")
                onShouldStartTrip?()
            }

        case .active:
            if analyzer.shouldPause(accelerations: accelBuffer, currentLocation: lastKnownLocation) {
                state = .paused
                lastIdleTimestamp = now
                print("[MovementMonitor] trip paused")
                onShouldPauseTrip?()
            } else {
                lastMotionTimestamp = now
            }

        case .paused:
            if analyzer.shouldResume(accelerations: accelBuffer, previousLocation: lastKnownLocation) {
                state = .active
                lastMotionTimestamp = now
                print("[MovementMonitor] trip resumed")
                onShouldResumeTrip?()
            }
            // stopTrip logic remains handled by countdown timer
        }
    }
}

private enum MotionState {
    case idle     // no motion
    case primed   // acceleration threshold detected
    case active   // trip recording
    case paused   // waiting for resume or stop
}
