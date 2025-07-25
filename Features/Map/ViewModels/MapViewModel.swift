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
    @Published var traceSegments: [[CLLocationCoordinate2D]] = []
    private var traceOrigin: CLLocationCoordinate2D?
    
    private var hasInitializedHeading = false
    private let travelStateManager: TravelStateManager
    
    var locationIconName: String {
        switch cameraManager.orientationMode {
        case .northUp: "location.north.line"
        case .headingUp: "location.north.line.fill"
        }
    }
    
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
    
    init(
        travelLocationPredictor: TravelLocationPredictor,
        cameraManager: CameraManager,
        arrowManager: ArrowHeadingManager,
        zoomStore: ZoomLevelStore = ZoomLevelStore(),
        travelStateManager: TravelStateManager
    ) {
        self.travelLocationPredictor = travelLocationPredictor
        self.cameraManager = cameraManager
        self.arrowManager = arrowManager
        self.zoomStore = zoomStore
        self.travelStateManager = travelStateManager
        self.cameraPosition = zoomStore.load().map { .region($0) } ?? .automatic
        super.init()
        
        cameraManager.$desiredCameraPosition
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] mapCamera in
                guard let self else { return }
                if self.travelStateManager.state == .traveling {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.cameraPosition = .camera(mapCamera)
                    }
                } else {
                    self.cameraPosition = .camera(mapCamera)
                }
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
        
        let current = cameraManager.orientationMode
        let next: CameraOrientationMode
        if current == .headingUp {
            next = .northUp
        } else {
            next = .headingUp
        }
        
        cameraManager.setOrientationMode(next)
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
                self.animateLocationTransition(from: self.lastAnimatedLocation, to: location, speed: speed)
                
            }
            .store(in: &cancellables)
        
        cameraManager.$desiredCameraPosition
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newCamera in
                self?.cameraPosition = .camera(newCamera)
            }
            .store(in: &cancellables)
        
        travelStateManager.$state
            .removeDuplicates()
            .scan((TravelStateManager.TravelState.idle, TravelStateManager.TravelState.idle)) { ($0.1, $1) }
            .sink { [weak self] oldState, newState in
                guard let self else { return }
                switch (oldState, newState) {
                case (.idle, .traveling):
                    self.traceSegments = [[]]
                case (.paused, .traveling):
                    self.traceSegments.append([])
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
            // Update traceSegments in sync with arrow animation
            if self.traceSegments.isEmpty {
                self.traceSegments = [[CLLocationCoordinate2D(latitude: lat, longitude: lon)]]
            } else if let lastIndex = self.traceSegments.indices.last {
                self.traceSegments[lastIndex].append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }

            if t >= 1.0 {
                timer.invalidate()
                self.animationTimer = nil
                self.lastAnimatedLocation = end
            }
        }
    }
}
