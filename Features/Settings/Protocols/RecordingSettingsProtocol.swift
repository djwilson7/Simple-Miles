//
//  RecordingSettingsProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
import Foundation

protocol RecordingSettingsProtocol: ObservableObject {
    var autoStartEnabled: Bool { get set }
    var autoStopEnabled: Bool { get set }
    var motionSensitivity: MotionSensitivityLevel { get set }
}
