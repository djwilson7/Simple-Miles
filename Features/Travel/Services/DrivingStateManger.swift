import Foundation
import CoreLocation
import Combine

final class DrivingStateManager: ObservableObject {
    
    static let shared = DrivingStateManager()
    @Published private(set) var state: Bool = false
    
    private let movementDistanceThreshold: CLLocationDistance = 10.0
    private let speedThreshold: CLLocationSpeed = 2.5 // ~1.1 mph
    private let locationManager = LocationManager.shared
    private var lastMovementTime: Date = Date()
    private var evaluationTimer: Timer?
    private var lastEvaluatedLocation: LocationPoint?
    private let jumpDistanceThreshold: CLLocationDistance = 150 // meters (~0.25 miles)
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        observeLocation()
    }
    
    private func observeLocation() {
        locationManager.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current in
                self?.evaluateMotion(current: current)
            }
            .store(in: &cancellables)
    }
    
    private func evaluateMotion(current: LocationPoint) {
        guard let last = lastEvaluatedLocation else {
            lastEvaluatedLocation = current
            return
        }
        
        let distance = current.distance(to: last)
        let speed = locationManager.speed
        
        // Ignore small movements (jitter)
        if distance < movementDistanceThreshold {
            return
        }
        
        // Ignore jumps: don't emit driving for jumps, just update the anchor
        if distance > jumpDistanceThreshold {
            print("GPS jump detected (\(distance)m) — not emitting driving state.")
            lastEvaluatedLocation = current // Reset anchor to current location
            return
        }
        
        // Normal driving detection
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
        evaluationTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.state && Date().timeIntervalSince(self.lastMovementTime) > 10 {
                self.state = false
            }
        }
    }
}
