//
//  RecordingSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class RecordingSettings: RecordingSettingsProtocol {
    @Published var autoStartEnabled: Bool {
        didSet { store.set(.autoStartEnabled, value: autoStartEnabled) }
    }

    @Published var autoStopEnabled: Bool {
        didSet { store.set(.autoStopEnabled, value: autoStopEnabled) }
    }

    @Published var motionSensitivity: MotionSensitivityLevel {
        didSet { store.set(.motionSensitivity, value: motionSensitivity.rawValue) }
    }

    private let store: SettingsStoring

    init(store: SettingsStoring) {
        self.store = store
        autoStartEnabled = store.getBool(.autoStartEnabled, default: true)
        autoStopEnabled = store.getBool(.autoStopEnabled, default: true)
        motionSensitivity = store.getEnum(.motionSensitivity, default: .medium)
    }
}
