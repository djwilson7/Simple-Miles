//
//  SettingsStoreProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on [Your Date Here]
//

import Foundation
import CoreLocation

protocol SettingsStoreProtocol {
    // MARK: - Recording
    var motionSensitivity: MotionSensitivityLevel { get set }
    var pauseDuration: TimeInterval { get set }
    var minimumTripDistance: Double { get set }
    var baseSpeedThreshold: CLLocationSpeed { get set }
    var baseDistanceThreshold: CLLocationDistance { get set }

    // MARK: - Display
    var distanceUnit: DistanceUnit { get set }
    var timeFormat: TimeFormat { get set }
    var systemColorTheme: SystemColorTheme { get set }
    var accessibilityColorTheme: AccessibilityColorTheme { get set }
    var appColorTheme: AppColorTheme { get set }

    // MARK: - Export
    var includeRawCoordinates: Bool { get set }
    var exportFieldOptions: Set<ExportField> { get set }
    var defaultExportFileNamePrefix: String { get set }

    // MARK: - Classification
    var defaultTripType: TripType { get set }
    var businessModeEnabled: Bool { get set }
    var useProbabilisticTagging: Bool { get set }
    var classificationMode: ClassificationMode { get set }
    var customLabels: [String] { get set }
    
    // MARK: - Privacy
    var privacyConsentLevel: PrivacyConsentLevel { get set }

}
