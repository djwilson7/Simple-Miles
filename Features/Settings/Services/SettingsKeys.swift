//
//  SettingsKeys.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

enum SettingsKey: String, CaseIterable {
    // MARK: - Recording
    case motionSensitivity
    case pauseDuration
    case minimumTripDistance
    case baseSpeedThreshold
    case baseDistanceThreshold

    // MARK: - Display
    case distanceUnit
    case timeFormat
    case systemColorTheme
    case accessibilityColorTheme
    case appColorTheme

    // MARK: - Export
    case includeRawCoordinates
    case exportFieldOptions
    case defaultExportFileNamePrefix

    // MARK: - Classification
    case defaultTripType
    case businessModeEnabled
    case useProbabilisticTagging
    case classificationMode
    case customLabels

    // MARK: - Data Privacy
    case privacyConsentLevel
}
