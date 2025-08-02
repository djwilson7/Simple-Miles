//
//  AppSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/27/25.
//



import Foundation
import Combine
import SwiftUI

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @AppStorage("minimumTripDistance") var minimumTripDistance: Double = 0.25 {
        didSet {
            objectWillChange.send()
            minTripDistance.set(value: minimumTripDistance)
        }
    }

    let minTripDistance = SettingItem(
        title: "Minimum Trip Distance",
        description: "Min Distance a trip needs to be.",
        value: 0.25
    )
    
    @AppStorage("pauseTimer") var pauseTimer: Double = 180 {
        didSet {
            objectWillChange.send()
            pauseTimerDuration.set(value: pauseTimer)
        }
    }

    let pauseTimerDuration = SettingItem(
        title: "Pause Timer Duration",
        description: "Minimum seconds before a paused trip ends.",
        value: 180
    )
    
    private init() {}
}
