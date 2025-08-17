import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

@MainActor
final class MapViewModel: NSObject, ObservableObject {
    @Published var currentLocation: LocationPoint?
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
    private var currentStaticLast: LocationPoint?

    // Review overlays
    @Published var tripMarkers: [CLLocationCoordinate2D] = []
    @Published var previousTripPath: [CLLocationCoordinate2D] = []
    @Published var isLoadingReviewPath: Bool = false
    @Published private var hasEnteredReviewMode: Bool = false

    private var traceOrigin: CLLocationCoordinate2D?
    private var hasInitializedHeading = false

    var locationIconName: String {
        switch cameraManager.orientationMode {
        case .northUp, .freeRoam: "location.north.line"
        case .headingUp: "location.north.line.fill"
        case .reviewing: ""
        }
    }
    
    private let travelStateManager = TravelStateManager.shared
    let tripViewModel = TripViewModel.shared
    let recordingManager = RecordingManager.shared
    private let cameraManager = CameraManager.shared
    let arrowManager = ArrowHeadingManager.shared
    private let travelLocationPredictor = TravelLocationPredictor.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var savedFreeRoamZoom: CLLocationDistance?

    var mapHeading: CLLocationDirection { lastCamera?.heading ?? 0 }

    // Location animation
    private let locationAnimationManager = LocationAnimationManager()

    // Camera animation
    private let cameraAnimationManager = CameraAnimationManager()

    // Cached paths
    private var cachedCommitedPath: [LocationPoint] = []
    private var cachedNonCommitedPath: [LocationPoint] = []
    private var cachedPreviousTripPath: [LocationPoint] = []

    // Anchor for animated tail (last fixed live point)
    private var liveTailAnchor: LocationPoint?

    override init() {
        self.autoFollowEnabled = true
        self.cameraPosition = .automatic
        super.init()
        
        cameraManager.$desiredCameraPosition
            .receive(on: RunLoop.main)
            .sink { [weak self] newCamera in
                Task { @MainActor in
                    guard let self else { return }
                    guard let newCamera = newCamera else { return }
                    
                    let current = self.lastCamera
                    let headingChanged = (current?.heading ?? 0) != newCamera.heading
                    let centerChanged = current?.centerCoordinate.latitude != newCamera.centerCoordinate.latitude ||
                    current?.centerCoordinate.longitude != newCamera.centerCoordinate.longitude
                    
                    if headingChanged || centerChanged {
                        if self.travelStateManager.state == .idle && MainStateDriver.shared.mainState != .review {
                            // Instantly update camera, no animation
                            self.cameraPosition = .camera(newCamera)
                        } else {
                            // Animate heading/camera change
                            self.cameraAnimationManager.animate(
                                from: current ?? newCamera,
                                to: newCamera,
                                isReviewing: MainStateDriver.shared.mainState == .review,
                                onUpdate: { [weak self] interpolated in
                                    self?.cameraPosition = .camera(interpolated)
                                }
                            )
                        }
                    }
                    self.lastCamera = newCamera
                }
            }
            .store(in: &cancellables)
        cameraManager.updateOrientationMode(.northUp)
        bindStreams()
    }

    // MARK: - Public Controls

    func recenter() {
        autoFollowEnabled = true
        isUserInteracting = false
        switch cameraManager.orientationMode {
        case .reviewing, .freeRoam:
            cameraManager.resetOrientation()
        case .northUp:
            cameraManager.updateOrientationMode(.headingUp)
        case .headingUp:
            cameraManager.updateOrientationMode(.northUp)
        }
    }

    func userInteracting() {
        if autoFollowEnabled {
            autoFollowEnabled = false
            isUserInteracting = true
            cameraManager.updateOrientationMode(.freeRoam)
        }
    }


    // MARK: - Streams

    private var lastAnimatedLocation: LocationPoint?

    @MainActor private func bindStreams() {
        travelLocationPredictor.$activeLocation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self, let location else { return }

                if self.currentLocation == nil {
                    self.cameraPosition = .camera(
                        MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0)
                    )
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
            .scan((TravelState.idle, TravelState.idle)) { ($0.1, $1) }
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


        arrowManager.$desiredArrowRotation
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

        MainStateDriver.shared.$mainState
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mainState in
                guard let self else { return }
                if mainState == .review {
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
        isLoadingReviewPath = true
        hasEnteredReviewMode = true
        autoFollowEnabled = false
        isUserInteracting = false

        // Clear anchors so no tail is drawn during review
        liveTailAnchor = nil
        currentStaticLast = nil
        locationAnimationManager.updateAnchors(live: nil, staticLast: nil)

        // Prepare trip markers
        previousTripPath = cachedPreviousTripPath.map(\.coordinate)
        if !previousTripPath.isEmpty {
            tripMarkers = [previousTripPath.first!, previousTripPath.last!]
        } else {
            tripMarkers = []
        }

        // CameraManager now publishes the review camera position, which is then animated by the desiredCameraPosition sink.
        cameraManager.updateOrientationMode(.reviewing)
        cameraManager.setCameraToReview(path: cachedPreviousTripPath.map(\.coordinate))

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.isLoadingReviewPath = false
            self.updateDisplayedTracePath()
        }
    }

    private func handleIsNotReviewing() {
        cameraManager.resetOrientation()
        hasEnteredReviewMode = false
        
        tripViewModel.resetReviewState()
        
        autoFollowEnabled = true
        isUserInteracting = false

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

    /// Passes the given camera distance to the CameraManager for persistence.
    func saveUserCameraDistance(_ distance: CLLocationDistance) {
        cameraManager.saveUserCameraDistance(distance)
    }
    
    /// Intended for use by the map gesture handler.
    /// Call this method whenever the user rotates the map in free roam mode to update the heading.
    func updateFreeRoamHeading(_ heading: CLLocationDirection) {
        cameraManager.setCameraToFreeRoam(heading: heading)
    }

    // MARK: - Paths

    private func updateDisplayedTracePath() {
        if MainStateDriver.shared.mainState == .review {
            commitedTracePath = []
            nonCommitedTraceStatic = []
            nonCommitedTraceTail = []
            previousTripPath = self.cachedPreviousTripPath.map(\.coordinate)
            if !previousTripPath.isEmpty {
                tripMarkers = [previousTripPath.first!, previousTripPath.last!]
            } else {
                tripMarkers = []
            }
            cameraManager.setCameraToReview(path: previousTripPath)
        } else {
            commitedTracePath = self.cachedCommitedPath.map(\.coordinate)
            nonCommitedTraceStatic = self.cachedNonCommitedPath.map(\.coordinate)
            if !locationAnimationManager.isAnimating {
                nonCommitedTraceTail = []
            }
            previousTripPath = []
            tripMarkers = []
        }
    }
}
