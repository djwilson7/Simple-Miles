import Foundation
import CoreLocation
import Combine

/// Manages the driving state of the user based on location updates.
/// This singleton observes location changes and evaluates motion to determine
/// if the user is currently driving.
final class DrivingStateManager: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared singleton instance of `DrivingStateManager`.
    static let shared = DrivingStateManager()
    
    // MARK: - Published State
    
    /// Published property indicating whether the user is currently driving.
    @Published private(set) var state: Bool = false
    
    // MARK: - Thresholds & Timing
    
    /// Distance threshold (in meters) to consider movement significant.
    private let movementDistanceThreshold: CLLocationDistance = 10.0
    
    /// Speed threshold (in meters per second) to consider the user moving.
    private let speedThreshold: CLLocationSpeed = 2.5 // ~1.1 mph
    
    // MARK: - Dependencies
    
    /// Shared location manager providing location updates.
    private let locationManager = LocationManager.shared
    
    // MARK: - Internal State
    
    /// The last time significant movement was detected.
    private var lastMovementTime: Date = Date()
    
    /// Timer to periodically evaluate if the driving state should be reset.
    private var evaluationTimer: Timer?
    
    /// The last evaluated location used to compute distance moved.
    private var lastEvaluatedLocation: CLLocation?
    
    // MARK: - Combine Subscriptions
    
    /// Set to hold Combine cancellable subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Private initializer to enforce singleton usage.
    private init() {
        // Intentionally left empty. Call initialize() to start observation.
    }
    
    /// Initializes the DrivingStateManager's observation logic. Call once on app launch.
    func initialize() {
        observeLocation()
    }
    
    // MARK: - Driving State Observation
    
    /// Sets up observation of location updates from the location manager.
    private func observeLocation() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                self?.evaluateMotion(current: current)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Motion Evaluation Logic
    
    /// Evaluates the current motion based on location and speed to update driving state.
    /// - Parameter current: The current CLLocation to evaluate.
    private func evaluateMotion(current: CLLocation) {
        guard let last = lastEvaluatedLocation else {
            lastEvaluatedLocation = current
            return
        }
        
        let distance = current.distance(from: last)
        let speed = locationManager.speed
        
        if distance > movementDistanceThreshold && speed > speedThreshold {
            lastEvaluatedLocation = current
            lastMovementTime = Date()
            resetEvaluationTimer()
            if !state {
                state = true
            }
        }
    }
    
    // MARK: - Timer Management
    
    /// Resets and schedules the evaluation timer to update driving state after a delay.
    private func resetEvaluationTimer() {
        evaluationTimer?.invalidate()
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.state && Date().timeIntervalSince(self.lastMovementTime) > 10 {
                self.state = false
            }
        }
    }
}
