//
//  SharedAppGroup.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/2/25.
//

import Foundation

let appGroupID = "group.i-maneo.SimpleMiles"

enum SharedKeys {
    static let tripState = "tripState"
    static let tripDistanceCommitted = "tripDistanceCommitted"
    static let tripDistanceLive = "tripDistanceLive"
    static let tripDurationCommitted = "tripDurationCommitted"
    static let tripDurationLive = "tripDurationLive"
    static let sweepProgress = "sweepProgress"
    static let remainingPauseTime = "remainingPauseTime"
}

func getSharedDefaults() -> UserDefaults? {
    UserDefaults(suiteName: appGroupID)
}
