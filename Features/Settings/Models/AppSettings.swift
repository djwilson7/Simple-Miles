/*
Application Settings Reference (brainstormed)

1. Trip/Activity Parameters
   - Minimum Trip Distance
   - Maximum Trip Distance
   - Pause Timer Duration
   - Maximum Pause Timer
   - Auto-start/stop trip detection
   - GPS accuracy mode (high/medium/low)

2. User Experience
   - Units (miles vs. kilometers)
   - Theme (light/dark/system)
   - Language / Localization
   - Notification preferences (e.g., trip started, trip ended, achievements)
   - Enable/disable sounds
   - Vibration feedback

3. Privacy & Data
   - Save trip history (yes/no)
   - Share trip data with cloud (yes/no)
   - Export trips (CSV, GPX, etc.)
   - Allow background location updates
   - Data retention period

4. Map & Navigation
   - Default map type (standard, satellite, hybrid)
   - Show traffic overlays
   - Waypoint marker style
   - Show/hide live speed

5. Goals & Gamification
   - Daily/weekly trip goals (distance, number of trips, duration)
   - Badges/achievements enabled
   - Trip reminders

6. Advanced
   - Debug mode/logging
   - Reset all settings to default
   - App version display
*/

import Foundation
import Combine
import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var tripSettings: [SettingModel] = []
    
    var pauseTimerModel: SettingModel!
    var minimumTripDistanceModel: SettingModel!

    private init() {
        minimumTripDistanceModel = SettingModel(
            title: "Minimum Trip Distance",
            description: "Min Distance a trip needs to be.",
            userDefaultsKey: "minimumTripDistance",
            controlType: SettingControlType.stepper(min: 0.1, max: 2.0, step: 0.1),
            value: SettingValue.double(0.25)
        )
        
        pauseTimerModel = SettingModel(
            title: "Pause Timer Duration",
            description: "Minimum seconds before a paused trip ends.",
            userDefaultsKey: "pauseTimer",
            controlType: SettingControlType.stepper(min: 30, max: 600, step: 30),
            value: SettingValue.double(180)
        )
        
        tripSettings = [minimumTripDistanceModel, pauseTimerModel]

    }

}
