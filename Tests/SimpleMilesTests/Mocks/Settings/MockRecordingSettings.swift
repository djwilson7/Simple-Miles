//
//  MockRecordingSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockRecordingSettings: RecordingSettingsProtocol {
    var autoStartEnabled: Bool = true
    var autoStopEnabled: Bool = true
    var motionSensitivity: MotionSensitivityLevel = .medium
}
