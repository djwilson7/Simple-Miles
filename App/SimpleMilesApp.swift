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
    let cameraManager: CameraManager
    let arrowManager: ArrowHeadingManager
    let mapViewModel: MapViewModel
    let tripViewModel: TripViewModel
    let userNotifier = UserNotifier.shared
    let mapContainerViewModel: MapContainerViewModel
    let activityViewModel: ActivityViewModel
    
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
        
        tripViewModel = TripViewModel(
            recordingManager: recordingManager
        )
                
        cameraManager = CameraManager(
            travelLocationPredictor: travelLocationPredictor,
            tripViewModel: tripViewModel
        )
        
        arrowManager = ArrowHeadingManager(
            cameraManager: cameraManager,
            travelLocationPredictor: travelLocationPredictor,
            travelStateManager: travelStateManager,
            tripViewModel: tripViewModel
        )

        mapViewModel = MapViewModel(
            travelLocationPredictor: travelLocationPredictor,
            cameraManager: cameraManager,
            arrowManager: arrowManager,
            travelStateManager: travelStateManager,
            tripViewModel: tripViewModel,
            recordingManager: recordingManager
        )
        
        mapContainerViewModel = MapContainerViewModel (
            recordingManager: recordingManager,
            travelStateManager: travelStateManager,
            cameraManager: cameraManager,
            tripViewModel: tripViewModel
        )
        
        activityViewModel = ActivityViewModel(
            travelStateManager: travelStateManager,
            recordingManager: recordingManager,
            mapContainerViewModel: mapContainerViewModel
        )
    }

    var body: some Scene {
        WindowGroup {
            MapContainerView(
                viewModel: mapContainerViewModel,
                mapViewModel: mapViewModel
            )
            .environmentObject(driverStateManager)
            .environmentObject(travelStateManager)
            .environmentObject(activityViewModel)
        }
    }
}
