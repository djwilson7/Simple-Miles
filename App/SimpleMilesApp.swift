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
    let tripNotifier = TripStatusNotifier()
    
    init() {
        FirebaseApp.configure()
        print("[App] Simple_MilesApp launched")
        TripTrackingService.shared.startPassiveMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            MapContainerView(viewModel: MapContainerViewModel())
        }
    }
}
