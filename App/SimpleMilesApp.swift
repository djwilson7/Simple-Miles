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
    let recordingManager = RecordingManager.shared
    let userNotifier = UserNotifier.shared
    let cameraManager = CameraManager.shared
    let arrowManager = ArrowHeadingManager.shared
    
    let mapViewModel: MapViewModel
    let tripViewModel: TripViewModel
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
        recordingManager.initialize()
        cameraManager.initialize()
        arrowManager.initialize()
        
        tripViewModel = TripViewModel()

        mapViewModel = MapViewModel(
            travelLocationPredictor: travelLocationPredictor,
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

