//
//  AppIntent.swift
//  LiveTripTracking
//
//  Created by Invictus Maneo on 8/1/25.
//

import WidgetKit
import AppIntents
import Foundation

struct ExtendPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Extend Pause Timer"
    static var description = IntentDescription("Extend the trip pause timer by the user's default extension.")

    func perform() async throws -> some IntentResult {
        // Notify main app to extend pause timer
        getSharedDefaults()?.set(true, forKey: SharedKeys.extendPauseRequested)
        print("Extension for paused time requested")
        return .result()
    }
}

extension Notification.Name {
    static let extendPauseTimerRequested = Notification.Name("ExtendPauseTimerRequested")
}

