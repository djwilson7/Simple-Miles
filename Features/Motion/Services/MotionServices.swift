import Foundation
import CoreMotion
import Combine

struct MotionSample {
    let value: Double
    let timestamp: Date
}

final class MotionService {
    static let shared = MotionService()

    private let motionManager = CMMotionManager()
    private let accelerationSubject = PassthroughSubject<MotionSample, Never>()
    private var updateTimer: Timer?

    private(set) var latestAcceleration: Double = 0.0
    private var recentAccelerations: [Double] = []
    private let smoothingWindowSize: Int = 5
    private let updateInterval: TimeInterval = 0.5
    private let minimumAccelerationThreshold: Double = 0.02

    var accelerationPublisher: AnyPublisher<MotionSample, Never> {
        accelerationSubject.eraseToAnyPublisher()
    }

    private init() {}

    func startUpdates() {
        guard motionManager.isAccelerometerAvailable else { return }

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates()

        updateTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            self?.processCurrentAcceleration()
        }
    }

    func stopUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
        motionManager.stopAccelerometerUpdates()
        latestAcceleration = 0.0
        recentAccelerations.removeAll()
    }

    private func processCurrentAcceleration() {
        guard let data = motionManager.accelerometerData else { return }

        let vector = sqrt(
            pow(data.acceleration.x, 2) +
            pow(data.acceleration.y, 2) +
            pow(data.acceleration.z, 2)
        )

        let delta = max(0, vector - 1.0)
        let filtered = delta > minimumAccelerationThreshold ? delta : 0.0

        recentAccelerations.append(filtered)
        if recentAccelerations.count > smoothingWindowSize {
            recentAccelerations.removeFirst()
        }

        let average = recentAccelerations.reduce(0, +) / Double(recentAccelerations.count)
        latestAcceleration = average
        let sample = MotionSample(value: average, timestamp: Date())
        accelerationSubject.send(sample)
    }
}
