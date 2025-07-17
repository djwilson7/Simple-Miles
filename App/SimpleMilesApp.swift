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
    
    init() {
        FirebaseApp.configure()
        print("[App] Simple_MilesApp launched")
        TripTrackingService.shared.startPassiveMonitoring()
    }
    
    var body: some Scene {
        WindowGroup {
            DeveloperPanelView(
                viewModel: DeveloperPanelViewModel(
                    tripService: TripTrackingService.shared,
                    exportViewModel: TripExportViewModel()
                )
            )
//            if isLoggedIn {
//                ContentView()
//            } else {
//                LoginView()
//            }
        }
    }
}
