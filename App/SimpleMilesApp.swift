//
//  SimpleMilesApp.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import SwiftUI
import FirebaseCore

@main
struct SimpleMilesApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    let locationManager = LocationManager.shared
    let driverStateManager: DrivingStateManager
    let travelStateManager: TravelStateManager
    var recordingManager: RecordingManager
    let mapViewModel: MapViewModel
    let motionManager: MotionManager
    let tripTraceStore: TripTraceStore
    
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

        recordingManager = RecordingManager(
            travelStatePublisher: travelStateManager.$state,
            currentLocationPublisher: locationManager.$currentLocation,
            lastLocationPublisher: locationManager.$lastLocation,
        )
        
        tripTraceStore = TripTraceStore(
            isRecordingPublisher: recordingManager.$isRecording,
            travelStatePublisher: travelStateManager.$state,
            currentLocationPublisher: locationManager.$currentLocation,
            lastLocationPublisher: locationManager.$lastLocation
        )
        

        mapViewModel = MapViewModel(locationManager: locationManager, traceStore: tripTraceStore)
        motionManager = MotionManager.shared
        motionManager.observeTravelState(travelStateManager.$state.eraseToAnyPublisher())
    }

    var body: some Scene {
        WindowGroup {
            MapContainerView(
                viewModel: MapContainerViewModel(
                    recordingManager: recordingManager,
                    travelStateManager: travelStateManager
                ),
                mapViewModel: mapViewModel
            )
            .environmentObject(driverStateManager)
            .environmentObject(travelStateManager)
        }
    }
}
