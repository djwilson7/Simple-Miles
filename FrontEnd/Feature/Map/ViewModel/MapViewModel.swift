import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI
import UIKit

/// Orchestrates map camera, user location animation, and trace rendering for the Map view.
/// Bridges live app managers (location, camera, recording, review) into UI-facing @Published state.
@MainActor
final class MapViewModel: NSObject, ObservableObject {

    // MARK: - Published State (UI)
    @Published private(set) var currentLocation: LocationPoint?
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Published private(set) var autoFollowEnabled: Bool = false
    @Published private(set) var isUserInteracting: Bool = false
    @Published private(set) var lastCamera: MapCamera?
    @Published private(set) var displayedArrowRotation: CLLocationDirection = 0

    @Published private(set) var commitedTracePath: [CLLocationCoordinate2D] = []
    @Published private(set) var nonCommitedTraceStatic: [CLLocationCoordinate2D] = []
    @Published private(set) var nonCommitedTraceTail: [CLLocationCoordinate2D] = []

    @Published private(set) var tripMarkers: [CLLocationCoordinate2D] = []
    @Published private(set) var previousTripPath: [CLLocationCoordinate2D] = []
    @Published private(set) var isLoadingReviewPath: Bool = false

    @Published private(set) var mainState: MainStateManager.MainState = MainStateManager.shared.state

    // MARK: - Computed (UI-derived)
    var mapHeading: CLLocationDirection { lastCamera?.heading ?? 0 }

    var locationIconName: String {
        switch cameraManager.orientationMode {
        case .northUp, .freeRoam: "location.north"
        case .headingUp: "location.north.fill"
        case .reviewing: ""
        }
    }

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()

    private var currentStaticLast: LocationPoint?
    private var lastAnimatedLocation: LocationPoint?
    private var liveTailAnchor: LocationPoint?

    private var cachedCommitedPath: [LocationPoint] = []
    private var cachedNonCommitedPath: [LocationPoint] = []
    private var cachedPreviousTripPath: [CLLocationCoordinate2D] = []

    private let locationAnimationManager = LocationAnimationManager()
    private let cameraAnimationManager = CameraAnimationManager()

    // MARK: - Singletons (Dependencies)
    private let travelStateManager = TravelStateManager.shared
    private let tripViewModel = SortViewModel.shared
    private let recordingManager = RecordingManager.shared
    private let cameraManager = CameraManager.shared
    private let arrowManager = ArrowHeadingManager.shared
    private let locationPredictor = LocationPredictionManager.shared

    // MARK: - Init
    override init() {
        self.autoFollowEnabled = true
        self.cameraPosition = .automatic
        super.init()

        cameraManager.updateOrientationMode(.northUp)
        bind()
    }

    // MARK: - Public API (User Intents / Lifecycle)
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

    func updateLastCamera(_ camera: MapCamera) {
        lastCamera = camera
    }

    func saveUserCameraDistance(_ distance: CLLocationDistance) {
        cameraManager.saveUserCameraDistance(distance)
    }

    func updateFreeRoamHeading(_ heading: CLLocationDirection) {
        cameraManager.setCameraToFreeRoam(heading: heading)
    }

    // MARK: - Bindings (Streams wiring)
    private func bind() {
        // 1. High-Frequency Live State Sync (Puck, Tail, Camera)
        // We unify these into a single sink on RunLoop.main to ensure they update in the SAME frame.
        locationPredictor.$activeLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self, let location else { return }

                // Initial camera setup
                if self.currentLocation == nil {
                    self.cameraPosition = .camera(
                        MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0)
                    )
                }

                self.currentLocation = location

                if self.travelStateManager.state == .traveling {
                    // 1a. Update Spline Tail
                    let groundTruth = self.cachedNonCommitedPath.map(\.coordinate)
                    self.nonCommitedTraceTail = self.locationAnimationManager.generateSplineTail(
                        groundTruth: groundTruth,
                        puck: location.coordinate
                    )
                    
                    // 1b. Synchronized Camera Follow
                    // If auto-follow is enabled, we bypass the CameraAnimationManager middleman
                    // and lock the camera directly to the physics-driven smoothed puck.
                    if self.autoFollowEnabled && self.mainState == .main {
                        let currentAltitude = self.cameraManager.loadSavedCameraDistance() ?? 1500
                        let heading = self.cameraManager.orientationMode == .headingUp ? location.course : 0
                        
                        let camera = MapCamera(
                            centerCoordinate: location.coordinate,
                            distance: currentAltitude,
                            heading: heading,
                            pitch: 0
                        )
                        self.cameraPosition = .camera(camera)
                        self.lastCamera = camera
                    }
                } else {
                    self.nonCommitedTraceTail = []
                }
            }
            .store(in: &cancellables)

        // 2. Camera target updates (Idle/Review transitions only)
        cameraManager.$desiredCameraPosition
            .receive(on: RunLoop.main)
            .sink { [weak self] newCamera in
                guard let self, let newCamera = newCamera else { return }
                
                // Only use the animation manager if we AREN'T in active travel follow.
                // Travel follow is handled by the high-frequency location sink above.
                let isTraveling = self.travelStateManager.state == .traveling
                if !isTraveling || !self.autoFollowEnabled {
                    let current = self.lastCamera
                    if self.cameraChangeIsSignificant(current: current, new: newCamera) {
                        if self.travelStateManager.state == .idle && self.mainState != .review {
                            self.cameraPosition = .camera(newCamera)
                        } else {
                            self.cameraAnimationManager.animate(
                                from: current ?? newCamera,
                                to: newCamera,
                                duration: self.mainState == .review ? 0.8 : 0.95,
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

        // App lifecycle -> re-center when becoming active on main screen
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)

        // Travel state transitions -> reset paths on start
        travelStateManager.$state
            .removeDuplicates()
            .scan((TravelState.idle, TravelState.idle)) { ($0.1, $1) }
            .sink { [weak self] oldState, newState in
                guard let self else { return }
                switch (oldState, newState) {
                case (.idle, .traveling):
                    self.commitedTracePath = []
                    self.nonCommitedTraceStatic = []
                    self.nonCommitedTraceTail = []
                    self.liveTailAnchor = nil
                    self.locationAnimationManager.reset()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Arrow heading -> rotate displayed arrow
        arrowManager.$desiredArrowRotation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rotation in
                self?.displayedArrowRotation = rotation
            }
            .store(in: &cancellables)

        // Review selection path
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

        // Main app state -> review mode handling and local mirror
        MainStateManager.shared.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mainState in
                guard let self else { return }
                self.mainState = mainState
                if mainState == .review {
                    self.handleIsReviewing()
                } else {
                    self.handleIsNotReviewing()
                    self.recenter()
                }
            }
            .store(in: &cancellables)

        // Committed path updates
        recordingManager.$commitedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                guard let self else { return }
                self.cachedCommitedPath = path
                self.updateDisplayedTracePath()
            }
            .store(in: &cancellables)

        // Non-committed (live) path updates
        recordingManager.$nonCommitedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                guard let self else { return }

                if let last = path.last {
                    self.liveTailAnchor = last
                } else {
                    self.liveTailAnchor = nil
                }

                self.cachedNonCommitedPath = path
                self.currentStaticLast = self.cachedNonCommitedPath.last
                self.updateDisplayedTracePath()

                Log("static=\(self.cachedNonCommitedPath.count) anchor=\(self.liveTailAnchor != nil)")
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Helpers
    private func handleAppDidBecomeActive() {
        if mainState == .main {
            recenter()
        }
    }

    private func handleIsReviewing() {
        isLoadingReviewPath = true
        autoFollowEnabled = false
        isUserInteracting = false
        liveTailAnchor = nil
        currentStaticLast = nil

        previousTripPath = cachedPreviousTripPath
        setMarkers(from: previousTripPath)

        cameraManager.updateOrientationMode(.reviewing)
        cameraManager.setCameraToReview(path: cachedPreviousTripPath)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.isLoadingReviewPath = false
            self.updateDisplayedTracePath()
        }
    }

    private func handleIsNotReviewing() {
        cameraManager.resetOrientation()

        tripViewModel.resetReviewState()

        autoFollowEnabled = true
        isUserInteracting = false
    }

    private func updateDisplayedTracePath() {
        if mainState == .review {
            commitedTracePath = []
            nonCommitedTraceStatic = []
            nonCommitedTraceTail = []
            previousTripPath = self.cachedPreviousTripPath
            setMarkers(from: previousTripPath)
            cameraManager.setCameraToReview(path: previousTripPath)
        } else {
            commitedTracePath = self.cachedCommitedPath.map(\.coordinate)
            
            let groundTruth = self.cachedNonCommitedPath.map(\.coordinate)
            if travelStateManager.state == .traveling && groundTruth.count >= 2 {
                // To prevent flickering at the "seam", we hide the last ground-truth point
                // and let the spline tail handle the connection from the second-to-last GT point.
                nonCommitedTraceStatic = Array(groundTruth.dropLast())
            } else {
                nonCommitedTraceStatic = groundTruth
            }
            
            // nonCommitedTraceTail is managed by the activeLocation physics loop
            previousTripPath = []
            tripMarkers = []
        }
    }

    private func setMarkers(from path: [CLLocationCoordinate2D]) {
        if let first = path.first, let last = path.last {
            tripMarkers = [first, last]
        } else {
            tripMarkers = []
        }
    }

    private func cameraChangeIsSignificant(current: MapCamera?, new: MapCamera) -> Bool {
        guard let current else { return true }
        let centerDeltaM = coordinateDistanceMeters(current.centerCoordinate, new.centerCoordinate)
        let headingDelta = smallestHeadingDeltaDeg(current.heading, new.heading)
        let distanceDelta = abs(current.distance - new.distance)

        let centerThresholdM: CLLocationDistance = 0.5
        let headingThresholdDeg: CLLocationDirection = 0.5
        let distanceThresholdM: CLLocationDistance = 1.0

        return centerDeltaM > centerThresholdM ||
               headingDelta > headingThresholdDeg ||
               distanceDelta > distanceThresholdM
    }

    private func coordinateDistanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        let la = CLLocation(latitude: a.latitude, longitude: a.longitude)
        let lb = CLLocation(latitude: b.latitude, longitude: b.longitude)
        return la.distance(from: lb)
    }

    private func smallestHeadingDeltaDeg(_ a: CLLocationDirection, _ b: CLLocationDirection) -> CLLocationDirection {
        let delta = ((b - a + 540).truncatingRemainder(dividingBy: 360)) - 180
        return abs(delta)
    }

    // MARK: - Deinit
    deinit {
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
    }
}
