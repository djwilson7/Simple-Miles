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
    
    //Singleton Class References
    let locationManager = LocationManager.shared
    let driverStateManager = DrivingStateManager.shared
    let travelStateManager = TravelStateManager.shared
    let travelLocationPredictor = TravelLocationPredictor.shared
    
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
        locationManager.startSignificantChangeMonitoring()

        driverStateManager.initialize()
        
        travelStateManager.initialize()
        
        travelLocationPredictor.initialize()

        recordingManager = RecordingManager(
            travelStatePublisher: travelStateManager.$state,
            currentLocationPublisher: locationManager.$currentLocation,
            lastLocationPublisher: locationManager.$lastLocation
        )
        
        tripViewModel = TripViewModel()
                
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
