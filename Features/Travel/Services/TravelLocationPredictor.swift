import Foundation
import Combine
import CoreLocation
import MapKit

final class TravelLocationPredictor: ObservableObject {
    @Published private(set) var activeLocation: CLLocation?
    @Published private(set) var activeHeading: CLLocationDirection = 0
    @Published private(set) var userSpeed: CLLocationSpeed = 0

    private let locationManager: LocationManager
    private let travelStateManager: TravelStateManager

    private var cancellables = Set<AnyCancellable>()
    private var predictionTimer: Cancellable?

    private var lastLocation: CLLocation?
    private var lastHeading: CLLocationDirection = 0
    private var currentTravelState: TravelState = .idle

    init(locationManager: LocationManager, travelStateManager: TravelStateManager) {
        self.locationManager = locationManager
        self.travelStateManager = travelStateManager
        bindStreams()
    }

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

    private func predictedLocation(from location: CLLocation) -> CLLocation {
        let speed = max(location.speed, 0)
        let heading = location.course >= 0 ? location.course : activeHeading
        let predictionTime: TimeInterval = 1.0
        let distance = speed * predictionTime
        let projected = location.coordinate.coordinate(at: distance, bearing: heading)
        return CLLocation(latitude: projected.latitude, longitude: projected.longitude)
    }
}

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
