import Foundation
import Combine
import CoreLocation
import MapKit

/// Predicts near-future user location for smoother UI by combining live location,
/// heading, and travel state. Publishes activeLocation, activeHeading, and userMovementMode.
@MainActor
final class LocationPredictionManager: ObservableObject {

    // MARK: - Singleton
    static let shared = LocationPredictionManager()

    // MARK: - Published State (Outputs)
    @Published private(set) var activeLocation: LocationPoint?
    @Published private(set) var activeHeading: CLLocationDirection?
    @Published var userMovementMode: UserMovementMode = .idle

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    var lastRawLocation: LocationPoint?
    var lastRawHeading: CLLocationDirection?
    private var predictionTimer: Timer?

    // Physics State
    private var simulatedLocation: CLLocationCoordinate2D?
    private var simulatedSpeed: Double = 0
    private var simulatedCourse: Double = 0
    
    // Spring constants for "soft" reconciliation
    private let posSpringStrength: Double = 0.05   // 5% position correction per frame
    private let velSpringStrength: Double = 0.02   // 2% velocity/heading correction per frame
    
    private var lastFrameTime: Date?

    private init() {
        bindInputs()
    }

    // MARK: - Bindings
    private func bindInputs() {
        let locationManager = LocationManager.shared
        let travelStateManager = TravelStateManager.shared

        Publishers.CombineLatest3(
            locationManager.locationPublisher,
            locationManager.headingPublisher,
            travelStateManager.$state
        )
        .sink { [weak self] location, heading, travelState in
            Task { @MainActor in
                guard let self = self else { return }
                
                // We update our "Ground Truth" target, but we DON'T trigger a step here.
                // The 60fps timer handles the steps independently of GPS frequency.
                self.lastRawLocation = location
                self.lastRawHeading = heading
                self.userMovementMode = travelState == .traveling ? .driving : .idle
                self.updatePredictionState()
            }
        }
        .store(in: &cancellables)
    }

    func updatePredictionState() {
        if userMovementMode == .driving {
            if predictionTimer == nil {
                startPredictionTimer()
            }
        } else {
            predictionTimer?.invalidate()
            predictionTimer = nil
            activeLocation = lastRawLocation
            activeHeading = lastRawHeading
            
            // Sync simulation state for immediate takeover when driving resumes
            if let raw = lastRawLocation {
                simulatedLocation = raw.coordinate
                simulatedSpeed = raw.speed
                simulatedCourse = raw.course
            }
        }
    }

    private func startPredictionTimer() {
        lastFrameTime = Date()
        // Run at 60fps for buttery smoothness
        predictionTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.stepPrediction()
            }
        }
    }

    func stepPrediction() {
        let now = Date()
        let dt = now.timeIntervalSince(lastFrameTime ?? now)
        lastFrameTime = now
        
        if simulatedLocation == nil, let raw = lastRawLocation {
            simulatedLocation = raw.coordinate
            simulatedSpeed = raw.speed
            simulatedCourse = raw.course
        }
        
        guard let currentPos = simulatedLocation else { return }

        // 1. DEAD RECKONING
        let distance = simulatedSpeed * dt
        let projectedCoord = currentPos.coordinate(at: distance, bearing: simulatedCourse)

        // 2. DYNAMIC TARGET RECONCILIATION
        if let raw = lastRawLocation {
            // How old is our GPS ground truth?
            let age = now.timeIntervalSince(raw.timestamp)
            
            // PROJECTED TARGET: Where would the GPS point be NOW if it kept moving?
            // This prevents the "stop-go" by making the puck chase a moving goal.
            let targetDistance = raw.speed * age
            let dynamicTarget = raw.coordinate.coordinate(at: targetDistance, bearing: raw.course)
            
            // AGE-BASED RELAXATION:
            // If GPS is fresh, pull hard. If GPS is old (> 2.0s), relax the pull and trust dead reckoning.
            let relaxation = max(0, 1.0 - (age / 2.0))
            let currentPosPull = posSpringStrength * relaxation
            let currentVelPull = velSpringStrength * relaxation

            // Artificial Friction: If GPS is older than 2s, start slowing down the dead reckoning.
            // This prevents the puck from drifting forever if we lose the signal.
            if age > 2.0 {
                let friction: Double = 0.92 // ~8% speed reduction per frame at 60fps
                simulatedSpeed *= friction
                if simulatedSpeed < 0.1 { simulatedSpeed = 0 }
            }

            let lat = projectedCoord.latitude + (dynamicTarget.latitude - projectedCoord.latitude) * currentPosPull
            let lon = projectedCoord.longitude + (dynamicTarget.longitude - projectedCoord.longitude) * currentPosPull
            simulatedLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            simulatedSpeed += (raw.speed - simulatedSpeed) * currentVelPull
            simulatedCourse = interpolateCourse(from: simulatedCourse, to: raw.course, factor: currentVelPull)
        } else {
            simulatedLocation = projectedCoord
        }

        // 3. BROADCAST
        let interpolatedPoint = LocationPoint(
            coordinate: simulatedLocation!,
            timestamp: now,
            speed: simulatedSpeed,
            course: simulatedCourse
        )
        activeLocation = interpolatedPoint
        activeHeading = simulatedCourse
    }

    private func interpolateCourse(from: Double, to: Double, factor: Double) -> Double {
        var diff = (to - from).truncatingRemainder(dividingBy: 360)
        if diff > 180 { diff -= 360 }
        if diff < -180 { diff += 360 }
        let result = (from + diff * factor).truncatingRemainder(dividingBy: 360)
        return result < 0 ? result + 360 : result
    }

    private func predictLocation(from base: LocationPoint, heading: CLLocationDirection, interval: TimeInterval) -> LocationPoint {
        let distance = base.speed * interval
        let startCL = base.coordinate
        let predictedCL = startCL.coordinate(at: distance, bearing: heading)
        return LocationPoint(coordinate: predictedCL, timestamp: Date(), speed: base.speed, course: heading)
    }

    func reset() {
        activeLocation = nil
        activeHeading = nil
        lastRawLocation = nil
        lastRawHeading = nil
        simulatedLocation = nil
        simulatedSpeed = 0
        simulatedCourse = 0
        predictionTimer?.invalidate()
        predictionTimer = nil
    }
}

// MARK: - Supporting Types
enum UserMovementMode {
    case idle
    case driving
}
