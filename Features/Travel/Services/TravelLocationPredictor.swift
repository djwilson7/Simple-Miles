import Foundation
import Combine
import CoreLocation
import MapKit

// MARK: - TravelLocationPredictor

/// Predicts and updates the user's likely location and heading during travel.
/// - Singleton: Use `shared`. Call `initialize()` once at startup.
final class TravelLocationPredictor: ObservableObject {
    /// Shared singleton instance.
    static let shared = TravelLocationPredictor()
    
    /// Private initializer to enforce singleton usage.
    private init() {}

    // MARK: - Published Properties

    /// The current predicted or device location.
    @Published private(set) var activeLocation: CLLocation?
    /// The current heading in degrees clockwise from true north.
    @Published private(set) var activeHeading: CLLocationDirection = 0
    /// The user's speed in meters per second.
    @Published private(set) var userSpeed: CLLocationSpeed = 0

    // MARK: - Dependencies

    /// Provides location updates.
    private let locationManager = LocationManager.shared
    /// Manages travel state changes.
    private let travelStateManager = TravelStateManager.shared

    // MARK: - State

    /// Subscribers for Combine streams.
    private var cancellables = Set<AnyCancellable>()
    /// Timer used for periodic location prediction.
    private var predictionTimer: Cancellable?
    /// The most recent device location from the source.
    private var lastLocation: CLLocation?
    /// The last known true heading.
    private var lastHeading: CLLocationDirection = 0
    /// The current travel state.
    private var currentTravelState: TravelState = .idle

    // MARK: - Lifecycle

    /// Sets up stream bindings. Call once after launch.
    func initialize() {
        bindStreams()
    }

    // MARK: - Private Methods

    /// Subscribes to location, heading, and travel state publishers.
    /// Handles prediction timer lifecycle.
    private func bindStreams() {
        Publishers.CombineLatest3(locationManager.$currentLocation, locationManager.$trueHeading, travelStateManager.$state)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location, heading, travelState in
                guard let self, let location else { return }

                self.userSpeed = location.speed
                self.lastLocation = location
                self.lastHeading = heading
                self.activeHeading = heading
                self.currentTravelState = travelState

                if travelState != .traveling {
                    self.activeLocation = location
                    self.invalidatePredictionTimer()
                } else {
                    self.startPredictionTimer()
                }
            }
            .store(in: &cancellables)
    }

    /// Starts the prediction timer if not already running.
    private func startPredictionTimer() {
        guard predictionTimer == nil else { return }

        predictionTimer = Timer
            .publish(every: 1.0 / 15.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.currentTravelState == .traveling,
                      let loc = self.lastLocation else { return }

                self.activeLocation = self.predictedLocation(from: loc)
            }
    }

    /// Cancels and removes the prediction timer.
    private func invalidatePredictionTimer() {
        predictionTimer?.cancel()
        predictionTimer = nil
    }

    /// Calculates the next likely location based on speed, heading, and elapsed time.
    /// - Parameter location: Last known location.
    /// - Returns: New predicted location.
    private func predictedLocation(from location: CLLocation) -> CLLocation {
        let speed = max(location.speed, 0)
        let heading = location.course >= 0 ? location.course : activeHeading
        let predictionTime: TimeInterval = 1.0
        let distance = speed * predictionTime
        let projected = location.coordinate.coordinate(at: distance, bearing: heading)
        return CLLocation(latitude: projected.latitude, longitude: projected.longitude)
    }
}

// MARK: - CLLocationCoordinate2D Projection

/// CLLocationCoordinate2D projection utilities.
private extension CLLocationCoordinate2D {
    /// Projects a coordinate a certain distance (meters) in the given bearing (degrees).
    /// - Parameters:
    ///   - distance: Distance in meters.
    ///   - bearing: Bearing in degrees from true north.
    /// - Returns: New coordinate at the projected location.
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
