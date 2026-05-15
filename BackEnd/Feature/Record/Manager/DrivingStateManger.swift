import Foundation
import CoreLocation
import Combine

/// Derives a simple driving state (true/false) by observing location updates:
/// - Emits true when sustained movement above a speed threshold is detected.
/// - Falls back to false if no movement is observed for a grace period.
/// Filters out large GPS jumps to avoid false positives.
@MainActor
final class DrivingStateManager: ObservableObject {

    // MARK: - Singleton
    static let shared = DrivingStateManager()

    // MARK: - Dependencies
    private let locationManager = LocationManager.shared

    // MARK: - Published State (Outputs)
    @Published private(set) var state: Bool = false

    // MARK: - Private State
    var lastMovementTime: Date = Date()
    private var evaluationTimer: Timer?
    private var lastEvaluatedLocation: LocationPoint?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Configuration
    private let movementDistanceThreshold: CLLocationDistance = 10.0
    private let speedThreshold: CLLocationSpeed = 2.5
    private let jumpDistanceThreshold: CLLocationDistance = 150
    private let evaluationWindow: TimeInterval = 10.0

    // MARK: - Init
    private init() {
        observeLocation()
    }

    // MARK: - Bindings (Streams wiring)
    private func observeLocation() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                // Hop to MainActor explicitly to avoid capturing MainActor-isolated self in a @Sendable closure.
                Task { @MainActor in
                    guard let self else { return }
                    self.evaluateMotion(current: current)
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    func evaluateMotion(current: LocationPoint) {
        guard let last = lastEvaluatedLocation else {
            lastEvaluatedLocation = current
            return
        }

        let distance = current.distance(to: last)
        let speed = current.speed

        // Ignore tiny movements
        if distance < movementDistanceThreshold {
            return
        }

        // Filter out GPS jumps
        if distance > jumpDistanceThreshold {
            print("GPS jump detected (\(distance)m) — not emitting driving state.")
            lastEvaluatedLocation = current
            return
        }

        // Consider as movement only if above speed threshold
        if speed > speedThreshold {
            lastEvaluatedLocation = current
            lastMovementTime = Date()
            resetEvaluationTimer()
            if !state {
                state = true
            }
        }
    }

    private func resetEvaluationTimer() {
        evaluationTimer?.invalidate()

        // Use selector-based timer to avoid @Sendable closure capturing actor-isolated state.
        let timer = Timer(timeInterval: evaluationWindow, target: self, selector: #selector(handleEvaluationTimer(_:)), userInfo: nil, repeats: false)
        evaluationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        timer.tolerance = 0.1
    }

    @objc
    func handleEvaluationTimer(_ timer: Timer) {
        if state && Date().timeIntervalSince(lastMovementTime) > evaluationWindow {
            state = false
        }
    }

    func reset() {
        state = false
        lastEvaluatedLocation = nil
        lastMovementTime = Date.distantPast
    }
}
