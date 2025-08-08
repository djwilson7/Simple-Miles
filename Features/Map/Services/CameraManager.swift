import MapKit
import CoreLocation
import Combine
import SwiftUI

final class CameraManager: NSObject, ObservableObject {

    // MARK: - Public Published State
    @Published var orientationMode: CameraOrientationMode = .northUp
    @Published var currentHeading: CLLocationDirection = 0
    @Published var desiredCameraPosition: MapCamera? = nil

    // MARK: - Private Properties
    private var travelLocationPredictor: TravelLocationPredictor
    private let tripViewModel: TripViewModel
    private var isReviewing: Bool = false
    private var userZoomLevel: CLLocationDistance?
    private let headingTolerance: CLLocationDirection = 2.0
    private var lastProgrammaticHeading: CLLocationDirection = 0
    private var autoZoomEnabled: Bool = true
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        travelLocationPredictor: TravelLocationPredictor,
        tripViewModel: TripViewModel
    ) {
        self.travelLocationPredictor = travelLocationPredictor
        self.tripViewModel = tripViewModel
        super.init()
        bindTripReviewState()
        bindTravelMotionManager()
    }

    private func bindTripReviewState() {
        tripViewModel.$isReviewing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isReviewing, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Binding
    private func bindTravelMotionManager() {
        travelLocationPredictor.$activeLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self, !self.isReviewing else { return }
                self.updateCameraCenter(for: location)
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(travelLocationPredictor.$activeHeading, $orientationMode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heading, mode in
                guard let self, !self.isReviewing else { return }
                guard mode == .headingUp else { return }

                self.updateCameraHeading(to: heading)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Controls

    func setOrientationMode(_ mode: CameraOrientationMode) {
        if orientationMode == mode {
            orientationMode = (mode == .northUp) ? .headingUp : .northUp
        } else {
            orientationMode = mode
        }

        if let location = travelLocationPredictor.activeLocation {
            updateCameraCenter(for: location)
        }

        if orientationMode == .headingUp {
            let heading = travelLocationPredictor.activeHeading
            updateCameraHeading(to: heading)
        }
    }

    func enableAutoZoom(_ enabled: Bool) {
        autoZoomEnabled = enabled
    }

    func resetToNorth() {
        orientationMode = .northUp
        lastProgrammaticHeading = 0
        currentHeading = 0
        if let location = travelLocationPredictor.activeLocation {
            updateCameraCenter(for: location)
        }
    }

    // MARK: - Core Camera Update

    public func updateCameraCenter(for location: CLLocation) {
        let policy = MapOrientationPolicyFactory.policy(for: orientationMode)
        let heading = policy.cameraHeading(predictor: travelLocationPredictor, currentHeading: currentHeading)

        currentHeading = heading
        lastProgrammaticHeading = heading

        let altitude = userZoomLevel ?? 1500

        desiredCameraPosition = MapCamera(
            centerCoordinate: location.coordinate,
            distance: altitude,
            heading: heading,
            pitch: 0
        )
    }

    private func updateCameraHeading(to heading: CLLocationDirection) {
        guard let coordinate = travelLocationPredictor.activeLocation?.coordinate else { return }
        currentHeading = heading
        lastProgrammaticHeading = heading

        let altitude = userZoomLevel ?? 1500

        desiredCameraPosition = MapCamera(
            centerCoordinate: coordinate,
            distance: altitude,
            heading: heading,
            pitch: 0
        )
    }

    func currentZoomLevel() -> CLLocationDistance {
        userZoomLevel ?? 1500
    }

    func updateZoomLevel(_ altitude: CLLocationDistance) {
        userZoomLevel = altitude
    }
    
    // MARK: - Reviewing State Camera Controls

    func zoomToFitPath(_ coordinates: [CLLocationCoordinate2D], offset: CGFloat = 0.4) {
        guard !coordinates.isEmpty else { return }

        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude

        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let verticalAnchorRatio = 0.3 // adjust this as needed
        let shiftRatio = 0.7 - verticalAnchorRatio
        let latSpan = maxLat - minLat
        let verticalShiftDegrees = latSpan * shiftRatio

        let adjustedCenter = CLLocationCoordinate2D(
            latitude: centerLat - verticalShiftDegrees,
            longitude: centerLon
        )

        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        let horizontalPaddingFactor = 5.0
        let verticalPaddingFactor = 5.0 + Double(offset)
        let paddedLatDelta = latDelta * verticalPaddingFactor
        let paddedLonDelta = lonDelta * horizontalPaddingFactor
        let maxPaddedDelta = max(paddedLatDelta, paddedLonDelta)

        // Convert degrees to meters (approx.)
        let metersPerDegree = 111_000.0
        let boundingDistance = maxPaddedDelta * metersPerDegree
        let paddedDistance = boundingDistance

        // Apply vertical camera offset so trip fits in top 40% of screen (10–50% region)
        let clampedAltitude = min(max(paddedDistance, 1250), 350000) // sensible range

        // The adjustedCenter uses a vertical anchor to shift the path upward in the map frame.
        desiredCameraPosition = MapCamera(
            centerCoordinate: adjustedCenter, // vertically shifted to fit upper map segment
            distance: clampedAltitude,
            heading: 0,
            pitch: 0
        )
    }

    func resetAfterReview() {
        orientationMode = .northUp
        if let location = travelLocationPredictor.activeLocation {
            updateCameraCenter(for: location)
        }
    }
}
