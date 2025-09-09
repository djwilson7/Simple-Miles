import Foundation
import Combine
import CoreLocation
import MapKit

/// Predicts near-future user location for smoother UI by combining live location,
/// heading, and travel state. Publishes activeLocation, activeHeading, and userSpeed.
@MainActor
final class LocationPredictionManager: ObservableObject {

    // MARK: - Singleton
    static let shared = LocationPredictionManager()

    // MARK: - Dependencies
    private let locationManager = LocationManager.shared
    private let travelStateManager = TravelStateManager.shared

    // MARK: - Published State (Outputs)
    @Published private(set) var activeLocation: LocationPoint?
    @Published private(set) var activeHeading: CLLocationDirection = 0
    @Published private(set) var userSpeed: CLLocationSpeed = 0

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var predictionTimer: Cancellable?
    private var lastLocation: LocationPoint?
    private var lastHeading: CLLocationDirection = 0
    private var currentTravelState: TravelState = .idle

    // MARK: - Init
    private init() {
        bindStreams()
    }

    // MARK: - Bindings (Streams wiring)
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

    // MARK: - Private Helpers
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

    private func invalidatePredictionTimer() {
        predictionTimer?.cancel()
        predictionTimer = nil
    }

    private func predictedLocation(from location: LocationPoint) -> LocationPoint {
        let speed = max(location.speed, 0)
        let heading = location.course >= 0 ? location.course : activeHeading
        let predictionTime: TimeInterval = 1.0
        let distance = speed * predictionTime

        let projected = location.coordinate.coordinate(at: distance, bearing: heading)

        let predictedCL = CLLocation(
            coordinate: projected,
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            course: heading,
            speed: speed,
            timestamp: Date()
        )

        return LocationPoint(predictedCL)
    }
}

// MARK: - Geometry Helper
private extension CLLocationCoordinate2D {
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
