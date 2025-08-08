import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

// NOTE: When the user changes the map zoom while in .freeRoam mode, call cameraManager.setUserZoomLevel(currentAltitude) from your map view/coordinator to persist zoom.

final class MapViewModel: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Published var autoFollowEnabled: Bool = false
    @Published var manualRecenterRequested: Bool = false
    @Published var currentRegion: MKCoordinateRegion?
    @Published var isUserInteracting: Bool = false
    @Published private(set) var lastCamera: MapCamera?
    @Published var displayedArrowRotation: CLLocationDirection = 0

    // Committed + live paths
    @Published var commitedTracePath: [CLLocationCoordinate2D] = []
    @Published var nonCommitedTraceStatic: [CLLocationCoordinate2D] = []   // live path up to the last *fixed* point
    @Published var nonCommitedTraceTail: [CLLocationCoordinate2D] = []     // animated tail from last fixed to interpolated point
    private var currentStaticLast: CLLocationCoordinate2D?

    // Review overlays
    @Published var tripMarkers: [CLLocationCoordinate2D] = []
    @Published var previousTripPath: [CLLocationCoordinate2D] = []
    @Published var isLoadingReviewPath: Bool = false
    @Published private var hasEnteredReviewMode: Bool = false

    private var traceOrigin: CLLocationCoordinate2D?
    private var hasInitializedHeading = false
    private let travelStateManager: TravelStateManager
    let tripViewModel: TripViewModel

    var locationIconName: String {
        switch cameraManager.orientationMode {
        case .northUp: "location.north.line"
        case .headingUp: "location.north.line.fill"
        case .freeRoam: "circle.fill"
        }
    }
   

    let recordingManager: RecordingManager
    let cameraManager: CameraManager
    let arrowManager: ArrowHeadingManager
    private let travelLocationPredictor: TravelLocationPredictor
    private let zoomStore: ZoomLevelStore
    private var cancellables = Set<AnyCancellable>()
    
    private var savedFreeRoamZoom: CLLocationDistance?

    var mapHeading: CLLocationDirection { lastCamera?.heading ?? 0 }

    // Location animation
    private let locationAnimationManager = LocationAnimationManager()

    // Camera animation
    private let cameraAnimationManager = CameraAnimationManager()

    // Cached paths
    private var cachedCommitedPath: [CLLocationCoordinate2D] = []
    private var cachedNonCommitedPath: [CLLocationCoordinate2D] = []
    private var cachedPreviousTripPath: [CLLocationCoordinate2D] = []

    // Anchor for animated tail (last fixed live point)
    private var liveTailAnchor: CLLocationCoordinate2D?

    init(
        travelLocationPredictor: TravelLocationPredictor,
        cameraManager: CameraManager,
        arrowManager: ArrowHeadingManager,
        zoomStore: ZoomLevelStore = ZoomLevelStore(),
        travelStateManager: TravelStateManager,
        tripViewModel: TripViewModel,
        recordingManager: RecordingManager
    ) {
        self.travelLocationPredictor = travelLocationPredictor
        self.cameraManager = cameraManager
        self.arrowManager = arrowManager
        self.zoomStore = zoomStore
        self.travelStateManager = travelStateManager
        self.tripViewModel = tripViewModel
        self.autoFollowEnabled = true
        self.cameraPosition = zoomStore.load().map { .region($0) } ?? .automatic
        self.recordingManager = recordingManager
        super.init()
        
        cameraManager.$desiredCameraPosition
            .receive(on: RunLoop.main)
            .sink { [weak self] newCamera in
                guard let self else { return }
                guard let newCamera = newCamera else { return }
                
                let policy = MapOrientationPolicyFactory.policy(for: self.cameraManager.orientationMode)
                guard policy.allowsCenterUpdate else { return }
                
                let current = self.lastCamera
                let headingChanged = (current?.heading ?? 0) != newCamera.heading
                let centerChanged = current?.centerCoordinate.latitude != newCamera.centerCoordinate.latitude ||
                current?.centerCoordinate.longitude != newCamera.centerCoordinate.longitude
                
                let updatedCamera = newCamera
                
                if headingChanged || centerChanged {
                    if travelStateManager.state == .idle {
                        // Instantly update camera, no animation
                        self.cameraPosition = .camera(updatedCamera)
                    } else {
                        // Animate heading/camera change
                        cameraAnimationManager.animate(
                            from: current ?? updatedCamera,
                            to: updatedCamera,
                            isReviewing: tripViewModel.isReviewing,
                            onUpdate: { [weak self] interpolated in
                                self?.cameraPosition = .camera(interpolated)
                            }
                        )
                    }
                }
                self.lastCamera = updatedCamera
            }
            .store(in: &cancellables)
        
        if let savedAltitude = zoomStore.loadAltitude() {
            cameraManager.updateZoomLevel(savedAltitude)
        }
        
        cameraManager.setOrientationMode(.northUp)
        bindStreams()
    }

    // MARK: - Public Controls

    func recenter() {
        let policy = MapOrientationPolicyFactory.policy(for: cameraManager.orientationMode)
        autoFollowEnabled = policy.allowsAutoFollow
        isUserInteracting = false
        if cameraManager.orientationMode == .freeRoam {
            cameraManager.setOrientationMode(.northUp)
        }
    }

    func userInteracting() {
        if autoFollowEnabled {
            autoFollowEnabled = false
            isUserInteracting = true
            cameraManager.setOrientationMode(.freeRoam)
        }
    }

    func updateZoomRegion(_ region: MKCoordinateRegion) {
        zoomStore.save(region: region)
        zoomStore.save(altitude: cameraManager.currentZoomLevel())
        currentRegion = region
    }

    // MARK: - Streams

    private var lastAnimatedLocation: CLLocation?

    private func bindStreams() {
        travelLocationPredictor.$activeLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self, let location else { return }

                if self.currentLocation == nil {
                    if let savedRegion = zoomStore.load() {
                        self.cameraPosition = .region(savedRegion)
                    } else {
                        self.cameraPosition = .camera(
                            MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0)
                        )
                    }
                }

                let isTraveling = (self.travelStateManager.state == .traveling)

                self.locationAnimationManager.animate(
                    from: self.lastAnimatedLocation,
                    to: location,
                    travelStateIsTraveling: isTraveling,
                    onUpdate: { [weak self] interpolated, tail in
                        guard let self else { return }
                        self.currentLocation = interpolated
                        self.lastAnimatedLocation = interpolated
                        self.nonCommitedTraceTail = tail
                    }
                )
            }
            .store(in: &cancellables)


        travelStateManager.$state
            .removeDuplicates()
            .scan((TravelStateManager.TravelState.idle, TravelStateManager.TravelState.idle)) { ($0.1, $1) }
            .sink { [weak self] oldState, newState in
                guard let self else { return }
                switch (oldState, newState) {
                case (.idle, .traveling):
                    // Reset visual paths to avoid stale values after long pauses
                    self.commitedTracePath = []
                    self.nonCommitedTraceStatic = []
                    self.nonCommitedTraceTail = []
                    self.liveTailAnchor = nil

                    // Tell the animation manager to reset its internal cadence and speed state
                    self.locationAnimationManager.reset()

                default:
                    break
                }
            }
            .store(in: &cancellables)


        arrowManager.$displayedArrowRotation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rotation in
                self?.displayedArrowRotation = rotation
            }
            .store(in: &cancellables)

        $autoFollowEnabled
            .removeDuplicates()
            .sink { value in
                print("[MapViewModel] AutoFollow state changed: \(value)")
            }
            .store(in: &cancellables)

        tripViewModel.$selectedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                guard let self else { return }
                self.cachedPreviousTripPath = path
                if !self.isLoadingReviewPath {
                    self.updateDisplayedTracePath()
                }
            }
            .store(in: &cancellables)

        tripViewModel.$isReviewing
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReviewing in
                guard let self else { return }
                if isReviewing {
                    self.handleIsReviewing()
                } else {
                    self.handleIsNotReviewing()
                }
            }
            .store(in: &cancellables)


        // Committed path frames
        recordingManager.$commitedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                guard let self else { return }
                self.cachedCommitedPath = path
                self.updateDisplayedTracePath()
            }
            .store(in: &cancellables)

        // Live path frames
        recordingManager.$nonCommitedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                guard let self else { return }

                if let last = path.last {
                    self.liveTailAnchor = last
                } else {
                    self.liveTailAnchor = nil
                }

                self.cachedNonCommitedPath = Array(path)
                self.currentStaticLast = self.cachedNonCommitedPath.last
                self.locationAnimationManager.updateAnchors(
                    live: self.liveTailAnchor,
                    staticLast: self.currentStaticLast
                )
                self.updateDisplayedTracePath()

                print("[MapViewModel] Live path updated. static=\(self.cachedNonCommitedPath.count) anchor=\(self.liveTailAnchor != nil)")
            }
            .store(in: &cancellables)
    }
    
    private func handleIsReviewing() {
        savedFreeRoamZoom = cameraManager.currentZoomLevel()
        
        isLoadingReviewPath = true
        hasEnteredReviewMode = true
        autoFollowEnabled = true
        isUserInteracting = false

        // Clear anchors so no tail is drawn during review
        liveTailAnchor = nil
        currentStaticLast = nil
        locationAnimationManager.updateAnchors(live: nil, staticLast: nil)

        // Prepare trip markers
        previousTripPath = cachedPreviousTripPath
        if !previousTripPath.isEmpty {
            tripMarkers = [previousTripPath.first!, previousTripPath.last!]
        } else {
            tripMarkers = []
        }

        // Target camera to fit review path
        let reviewCamera = cameraToFitPath(cachedPreviousTripPath, offset: 0.3)
        let startCamera = lastCamera ?? MapCamera(
            centerCoordinate: reviewCamera.centerCoordinate,
            distance: reviewCamera.distance,
            heading: 0,
            pitch: 0
        )

        // Animate to review camera
        cameraAnimationManager.animate(
            from: startCamera,
            to: reviewCamera,
            isReviewing: true,
            onUpdate: { [weak self] interpolated in
                self?.cameraPosition = .camera(interpolated)
            }
        )

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.isLoadingReviewPath = false
            self.updateDisplayedTracePath()
        }
    }

    private func handleIsNotReviewing() {
        hasEnteredReviewMode = false
        if let previousZoom = savedFreeRoamZoom {
            cameraManager.updateZoomLevel(previousZoom)
        }
        tripViewModel.resetReviewState()

        if let current = currentLocation {
            let savedAltitude = zoomStore.loadAltitude() ?? 1500
            let userCamera = MapCamera(
                centerCoordinate: current.coordinate,
                distance: savedAltitude,
                heading: 0,
                pitch: 0
            )

            let startCamera = lastCamera ?? MapCamera(
                centerCoordinate: userCamera.centerCoordinate,
                distance: userCamera.distance,
                heading: 0,
                pitch: 0
            )

            // Animate back to user location
            cameraAnimationManager.animate(
                from: startCamera,
                to: userCamera,
                isReviewing: false,
                onUpdate: { [weak self] interpolated in
                    self?.cameraPosition = .camera(interpolated)
                }
            )

            autoFollowEnabled = true
            isUserInteracting = false
        }

        // Refresh anchors immediately on exit so tail re-anchors
        currentStaticLast = cachedNonCommitedPath.last
        locationAnimationManager.updateAnchors(
            live: liveTailAnchor,
            staticLast: currentStaticLast
        )
    }
    
    func updateLastCamera(_ camera: MapCamera) {
        lastCamera = camera
    }

    // MARK: - Paths

    private func updateDisplayedTracePath() {
        if tripViewModel.isReviewing {
            commitedTracePath = []
            nonCommitedTraceStatic = []
            nonCommitedTraceTail = []
            previousTripPath = self.cachedPreviousTripPath
            if !previousTripPath.isEmpty {
                tripMarkers = [previousTripPath.first!, previousTripPath.last!]
            } else {
                tripMarkers = []
            }
            self.cameraManager.zoomToFitPath(previousTripPath, offset: 0.3)
        } else {
            commitedTracePath = self.cachedCommitedPath
            nonCommitedTraceStatic = self.cachedNonCommitedPath
            if !locationAnimationManager.isAnimating {
                nonCommitedTraceTail = []
            }
            previousTripPath = []
            tripMarkers = []
        }
    }

    // MARK: - Location (arrow) animation

    
    private func coordsEqual(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D, eps: Double = 1e-7) -> Bool {
        abs(a.latitude - b.latitude) < eps && abs(a.longitude - b.longitude) < eps
    }

    /// Returns a MapCamera that fits the given path with the same offset logic as CameraManager.zoomToFitPath
    private func cameraToFitPath(_ coordinates: [CLLocationCoordinate2D], offset: CGFloat = 0.4) -> MapCamera {
        guard !coordinates.isEmpty else {
            if let userLocation = self.currentLocation?.coordinate {
                return MapCamera(centerCoordinate: userLocation, distance: 1500, heading: 0, pitch: 0)
            } else {
                return MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), distance: 1500, heading: 0, pitch: 0)
            }
        }

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

        let verticalAnchorRatio = 0.3
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

        let metersPerDegree = 111_000.0
        let boundingDistance = maxPaddedDelta * metersPerDegree
        let paddedDistance = boundingDistance

        let clampedAltitude = min(max(paddedDistance, 1250), 350000)
        return MapCamera(
            centerCoordinate: adjustedCenter,
            distance: clampedAltitude,
            heading: 0,
            pitch: 0
        )
    }

}
