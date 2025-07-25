//
//  SimpleMilesApp.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import SwiftUI
import FirebaseCore
import MapKit

@main
struct SimpleMilesApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    let locationManager = LocationManager.shared
    let driverStateManager: DrivingStateManager
    let travelStateManager: TravelStateManager
    let travelLocationPredictor: TravelLocationPredictor
    var recordingManager: RecordingManager
    let mapView: MKMapView
    let cameraManager: CameraManager
    let arrowManager: ArrowHeadingManager
    let mapViewModel: MapViewModel
//    let motionManager: MotionManager
    
    init() {
        FirebaseApp.configure()
        print("[App] Simple_MilesApp launched")

        locationManager.initialize()
        
        driverStateManager = DrivingStateManager(
            locationManager: locationManager
        )

        travelStateManager = TravelStateManager(
            drivingStatePublisher: driverStateManager.$state,
            locationManager: locationManager
        )

        travelLocationPredictor = TravelLocationPredictor(
            locationManager: locationManager,
            travelStateManager: travelStateManager
        )

        recordingManager = RecordingManager(
            travelStatePublisher: travelStateManager.$state,
            currentLocationPublisher: locationManager.$currentLocation,
            lastLocationPublisher: locationManager.$lastLocation
        )
        
        mapView = MKMapView()
        
        cameraManager = CameraManager(
            travelLocationPredictor: travelLocationPredictor
        )
        
        arrowManager = ArrowHeadingManager(
            cameraManager: cameraManager,
            travelLocationPredictor: travelLocationPredictor,
            travelStateManager: travelStateManager
        )

        mapViewModel = MapViewModel(
            travelLocationPredictor: travelLocationPredictor,
            cameraManager: cameraManager,
            arrowManager: arrowManager,
            travelStateManager: travelStateManager
        )
//        motionManager = MotionManager.shared
//        motionManager.observeTravelState(travelStateManager.$state.eraseToAnyPublisher())
    }

    var body: some Scene {
        WindowGroup {
            MapContainerView(
                viewModel: MapContainerViewModel(
                    recordingManager: recordingManager,
                    travelStateManager: travelStateManager,
                    cameraManager: cameraManager
                ),
                mapViewModel: mapViewModel
            )
            .environmentObject(driverStateManager)
            .environmentObject(travelStateManager)
        }
    }
}
