//
//  Simple_MilesApp.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/11/25.
//

import SwiftUI
import FirebaseCore

@main
struct Simple_MilesApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
            } else {
                LoginView()
            }
        }
    }
}
