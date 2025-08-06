import Foundation
import Combine
import CoreLocation
import MapKit
import SwiftUI

final class MapViewModel: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @Published var autoFollowEnabled: Bool = false
    @Published var manualRecenterRequested: Bool = false
    @Published var currentRegion: MKCoordinateRegion?
    @Published var isUserInteracting: Bool = false
    @Published private(set) var lastCamera: MapCamera?
    @Published var displayedArrowRotation: CLLocationDirection = 0
    @Published var nonCommitedTraceStatic: [CLLocationCoordinate2D] = []
    @Published var nonCommitedTraceTail: [CLLocationCoordinate2D] = []
    @Published var commitedTracePath: [CLLocationCoordinate2D] = []
    @Published var tripMarkers: [CLLocationCoordinate2D] = []
    @Published var previousTripPath: [CLLocationCoordinate2D] = []
    @Published var isLoadingReviewPath: Bool = false
    @Published private var hasEnteredReviewMode: Bool = false
    private var traceOrigin: CLLocationCoordinate2D?
    
    private var hasInitializedHeading = false
    private let travelStateManager: TravelStateManager
    let tripViewModel: TripViewModel
    
    var locationIconName: String {
        switch (cameraManager.orientationMode, self.autoFollowEnabled) {
        case (.northUp, true): "location.north.line"
        case (.headingUp, true): "location.north.line.fill"
        case (.northUp, false), (.headingUp, false): "circle.fill" //here we say if auto follow is disabled change icon.
        }
    }
    let recordingManager: RecordingManager
    let cameraManager: CameraManager
    let arrowManager: ArrowHeadingManager
    private let travelLocationPredictor: TravelLocationPredictor
    private let zoomStore: ZoomLevelStore
    private var cancellables = Set<AnyCancellable>()
    
    var mapHeading: CLLocationDirection {
        lastCamera?.heading ?? 0
    }
    
    private var animationTimer: Timer?
    private var animationStartLocation: CLLocation?
    private var animationTargetLocation: CLLocation?
    private var animationStartTime: Date?
    private var animationDuration: TimeInterval = 1.0
    private var cachedCommitedPath: [CLLocationCoordinate2D] = []
    private var cachedNonCommitedPath: [CLLocationCoordinate2D] = []
    private var cachedPreviousTripPath: [CLLocationCoordinate2D] = []
    
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
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] newCamera in
                guard let self else { return }
                
                let current = self.lastCamera

                let headingChanged = current?.heading != newCamera.heading
                let centerChanged = current?.centerCoordinate.latitude != newCamera.centerCoordinate.latitude ||
                                    current?.centerCoordinate.longitude != newCamera.centerCoordinate.longitude

                var updatedCamera = newCamera

                // If heading changed, apply smoothed transition for large changes
                if headingChanged {
                    let oldHeading = current?.heading ?? 0
                    let newHeading = newCamera.heading
                    let delta = abs(newHeading - oldHeading).truncatingRemainder(dividingBy: 360)

                    if delta > 30 {
                        let oldHeading = current?.heading ?? 0
                        let newHeading = newCamera.heading
                        // Determine if the shortest path is clockwise
                        let clockwise = ((newHeading - oldHeading + 360).truncatingRemainder(dividingBy: 360)) <= 180
                        let step = clockwise ? 5.0 : -5.0
                        var interpolatedHeading = oldHeading

                        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
                            interpolatedHeading += step
                            // Compute angular difference, always shortest path
                            let difference = (newHeading - interpolatedHeading + 540).truncatingRemainder(dividingBy: 360) - 180

                            if abs(difference) < abs(step) {
                                updatedCamera.heading = newHeading
                                self.cameraPosition = .camera(updatedCamera)
                                timer.invalidate()
                            } else {
                                updatedCamera.heading = interpolatedHeading.truncatingRemainder(dividingBy: 360)
                                self.cameraPosition = .camera(updatedCamera)
                            }
                        }
                    } else {
                        self.cameraPosition = .camera(updatedCamera)
                    }
                }
                // If only the center changed, animate
                else if centerChanged {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.cameraPosition = .camera(updatedCamera)
                    }
                }

                self.lastCamera = updatedCamera
            }
            .store(in: &cancellables)
        
        if let savedAltitude = zoomStore.loadAltitude() {
            cameraManager.setUserZoomLevel(savedAltitude)
        }
        
        cameraManager.setOrientationMode(.northUp)
        bindStreams()
    }
    
    func recenter() {
        autoFollowEnabled = true
        isUserInteracting = false
    }
    
    func updateZoomRegion(_ region: MKCoordinateRegion) {
        zoomStore.save(region: region)
        zoomStore.save(altitude: cameraManager.currentZoomLevel())
        currentRegion = region
    }
    
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
                        self.cameraPosition = .camera(MapCamera(centerCoordinate: location.coordinate, distance: 1500, heading: 0, pitch: 0))
                    }
                }
                
                let speed = location.speed >= 0 ? location.speed : 0
                if travelStateManager.state == .idle {
                    self.currentLocation = location
                    self.lastAnimatedLocation = location
                } else {
                    self.animateLocationTransition(from: self.lastAnimatedLocation, to: location, speed: speed)
                }
                
            }
            .store(in: &cancellables)
        
        
        travelStateManager.$state
            .removeDuplicates()
            .scan((TravelStateManager.TravelState.idle, TravelStateManager.TravelState.idle)) { ($0.1, $1) }
            .sink { [weak self] oldState, newState in
                guard let self else { return }
                switch (oldState, newState) {
                case (.idle, .traveling):
                    self.commitedTracePath = []
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
                print("AutoFollow state changed: \(value)")
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

                if isReviewing && !self.hasEnteredReviewMode {
                    self.isLoadingReviewPath = true
                    self.hasEnteredReviewMode = true
                    self.autoFollowEnabled = true
                    self.isUserInteracting = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        self.isLoadingReviewPath = false
                        self.updateDisplayedTracePath()
                    }
                } else if !isReviewing {
                    self.hasEnteredReviewMode = false
                    self.tripViewModel.resetReviewState() // Hard reset review/trip sorting state
                    if let current = self.currentLocation {
                        let savedAltitude = self.zoomStore.loadAltitude() ?? 1500
                        let camera = MapCamera(centerCoordinate: current.coordinate, distance: savedAltitude, heading: 0, pitch: 0)
                        self.cameraPosition = .camera(camera)
                        self.autoFollowEnabled = true
                        self.isUserInteracting = false
                    }
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
                self.cachedNonCommitedPath = path.dropLast()
                self.updateDisplayedTracePath()
            }
            .store(in: &cancellables)
    }
    
    private func updateDisplayedTracePath() {
        if tripViewModel.isReviewing {
            commitedTracePath = []
            nonCommitedTraceStatic = []
            previousTripPath = self.cachedPreviousTripPath
            if !previousTripPath.isEmpty{
                tripMarkers = [previousTripPath.first!, previousTripPath.last!]
            }
            self.cameraManager.zoomToFitPath(previousTripPath, offset: 0.3)
        } else {
            commitedTracePath = self.cachedCommitedPath
            nonCommitedTraceStatic = self.cachedNonCommitedPath
            previousTripPath = []
            tripMarkers = []
        }
    }
    
    private func animateLocationTransition(from start: CLLocation?, to end: CLLocation, speed: CLLocationSpeed) {
        guard travelStateManager.state == .traveling else {
            self.currentLocation = end
            self.lastAnimatedLocation = end
            return
        }
        
        guard let current = currentLocation ?? start else {
            self.currentLocation = end
            self.lastAnimatedLocation = end
            return
        }
        
        animationStartLocation = current
        animationTargetLocation = end
        animationStartTime = Date()
        
        animationDuration = {
            switch speed {
            case 0..<3: return 1.4
            case 3..<10: return 1.0
            case 10..<25: return 0.65
            default: return 0.5
            }
        }()
        
        startAnimationLoop()
    }
    
    private func startAnimationLoop() {
        animationTimer?.invalidate()
        var frameCount = 0
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard
                let self,
                let start = animationStartLocation,
                let end = animationTargetLocation,
                let startTime = animationStartTime
            else { return }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let t = min(elapsed / animationDuration, 1.0)
            
            let lat = start.coordinate.latitude + (end.coordinate.latitude - start.coordinate.latitude) * t
            let lon = start.coordinate.longitude + (end.coordinate.longitude - start.coordinate.longitude) * t
            self.currentLocation = CLLocation(latitude: lat, longitude: lon)
            
            frameCount += 1
            
            if t >= 1.0 {
                timer.invalidate()
                self.animationTimer = nil
                self.lastAnimatedLocation = end
            }
        }
    }
}
