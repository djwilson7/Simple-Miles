import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI
import UIKit

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

    @Published var commitedTracePath: [CLLocationCoordinate2D] = []
    @Published var nonCommitedTraceStatic: [CLLocationCoordinate2D] = []
    @Published var nonCommitedTraceTail: [CLLocationCoordinate2D] = []
    private var currentStaticLast: LocationPoint?

    @Published var tripMarkers: [CLLocationCoordinate2D] = []
    @Published var previousTripPath: [CLLocationCoordinate2D] = []
    @Published var isLoadingReviewPath: Bool = false
    @Published private var hasEnteredReviewMode: Bool = false

    private var traceOrigin: CLLocationCoordinate2D?
    private var hasInitializedHeading = false

    var locationIconName: String {
        switch cameraManager.orientationMode {
        case .northUp, .freeRoam: "location.north"
        case .headingUp: "location.north.fill"
        case .reviewing: ""
        }
    }
    
    private let travelStateManager = TravelStateManager.shared
    let tripViewModel = SortViewModel.shared
    let recordingManager = RecordingManager.shared
    private let cameraManager = CameraManager.shared
    let arrowManager = ArrowHeadingManager.shared
    private let locationPredictor = LocationPredictionManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private var savedFreeRoamZoom: CLLocationDistance?

    var mapHeading: CLLocationDirection { lastCamera?.heading ?? 0 }

    private let locationAnimationManager = LocationAnimationManager()

    private let cameraAnimationManager = CameraAnimationManager()

    private var cachedCommitedPath: [LocationPoint] = []
    private var cachedNonCommitedPath: [LocationPoint] = []
    private var cachedPreviousTripPath: [CLLocationCoordinate2D] = []

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
                        if self.travelStateManager.state == .idle && MainStateManager.shared.state != .review {
                            self.cameraPosition = .camera(newCamera)
                        } else {
                            self.cameraAnimationManager.animate(
                                from: current ?? newCamera,
                                to: newCamera,
                                isReviewing: MainStateManager.shared.state == .review,
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
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleAppDidBecomeActive()
            }
            .store(in: &cancellables)
    }


    private func handleAppDidBecomeActive() {
        if MainStateManager.shared.state == .main {
            recenter()
        }
    }

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

    private var lastAnimatedLocation: LocationPoint?

    @MainActor private func bindStreams() {
        locationPredictor.$activeLocation
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


        arrowManager.$desiredArrowRotation
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rotation in
                self?.displayedArrowRotation = rotation
            }
            .store(in: &cancellables)

        $autoFollowEnabled
            .removeDuplicates()
            .sink { value in
                Log("\(value)")
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

        MainStateManager.shared.$state
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mainState in
                guard let self else { return }
                if mainState == .review {
                    self.handleIsReviewing()
                } else {
                    self.handleIsNotReviewing()
                    self.recenter()
                }
            }
            .store(in: &cancellables)

        recordingManager.$commitedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] path in
                guard let self else { return }
                self.cachedCommitedPath = path
                self.updateDisplayedTracePath()
            }
            .store(in: &cancellables)

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

                Log("static=\(self.cachedNonCommitedPath.count) anchor=\(self.liveTailAnchor != nil)")
            }
            .store(in: &cancellables)
    }
    
    private func handleIsReviewing() {
        isLoadingReviewPath = true
        hasEnteredReviewMode = true
        autoFollowEnabled = false
        isUserInteracting = false
        liveTailAnchor = nil
        currentStaticLast = nil
        locationAnimationManager.updateAnchors(live: nil, staticLast: nil)

        previousTripPath = cachedPreviousTripPath
        if !previousTripPath.isEmpty {
            tripMarkers = [previousTripPath.first!, previousTripPath.last!]
        } else {
            tripMarkers = []
        }

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
        hasEnteredReviewMode = false
        
        tripViewModel.resetReviewState()
        
        autoFollowEnabled = true
        isUserInteracting = false

        currentStaticLast = cachedNonCommitedPath.last
        locationAnimationManager.updateAnchors(
            live: liveTailAnchor,
            staticLast: currentStaticLast
        )
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

    private func updateDisplayedTracePath() {
        if MainStateManager.shared.state == .review {
            commitedTracePath = []
            nonCommitedTraceStatic = []
            nonCommitedTraceTail = []
            previousTripPath = self.cachedPreviousTripPath
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
