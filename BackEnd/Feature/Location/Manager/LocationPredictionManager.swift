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
                self.lastRawLocation = location
                self.lastRawHeading = heading
                self.userMovementMode = travelState == .traveling ? .driving : .idle
                self.updatePredictionState()
            }
        }
        .store(in: &cancellables)
    }

    func updatePredictionState() {
        predictionTimer?.invalidate()
        predictionTimer = nil

        if userMovementMode == .driving {
            startPredictionTimer()
        } else {
            activeLocation = lastRawLocation
            activeHeading = lastRawHeading
        }
    }

    private func startPredictionTimer() {
        predictionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.stepPrediction()
            }
        }
    }

    func stepPrediction() {
        guard let base = lastRawLocation, let heading = lastRawHeading else { return }
        let speed = base.speed
        if speed < 1.0 {
            activeLocation = base
            activeHeading = heading
            return
        }

        // Simple linear prediction for 100ms
        let predicted = predictLocation(from: base, heading: heading, interval: 0.1)
        activeLocation = predicted
        activeHeading = heading
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
        predictionTimer?.invalidate()
        predictionTimer = nil
    }
}

// MARK: - Supporting Types
enum UserMovementMode {
    case idle
    case driving
}

// MARK: - Geometry Helper
extension CLLocationCoordinate2D {
    func coordinate(at distance: CLLocationDistance, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        let radius = 6_371_000.0
        let δ = distance / radius
        let θ = bearing * .pi / 180
        let φ1 = latitude * .pi / 180
        let λ1 = longitude * .pi / 180

        let φ2 = asin(sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ))
        let λ2 = λ1 + atan2(sin(θ) * sin(δ) * cos(φ1), cos(δ) - sin(φ1) * sin(φ2))

        return CLLocationCoordinate2D(
            latitude: φ2 * 180 / .pi,
            longitude: λ2 * 180 / .pi
        )
    }
}
