//
//  SettingsKeys.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

enum SettingsKey: String, CaseIterable {
    // Recording
    case autoStartEnabled
    case autoStopEnabled
    case motionSensitivity

    // Display
    case distanceUnit
    case timeFormat

    // Export
    case defaultExportFormat
    case includeRawCoordinates
    case defaultExportFileNamePrefix

    // Classification
    case defaultTripType
    
    // Data Privacy
    case privacyConsentLevel
}
