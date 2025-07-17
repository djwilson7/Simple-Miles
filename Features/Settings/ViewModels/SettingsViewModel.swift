//
//  SettingsViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

// SettingsViewModel.swift
import Foundation
import Combine

final class SettingsViewModel: ObservableObject {
    @Published var recording: any RecordingSettingsProtocol
    @Published var display: any DisplaySettingsProtocol
    @Published var export: any ExportSettingsProtocol
    @Published var classification: any ClassificationSettingsProtocol

    init(
        recording: any RecordingSettingsProtocol = RecordingSettings(store: SettingsStore.shared),
        display: any DisplaySettingsProtocol = DisplaySettings(store: SettingsStore.shared),
        export: any ExportSettingsProtocol = ExportSettings(store: SettingsStore.shared),
        classification: any ClassificationSettingsProtocol = ClassificationSettings(store: SettingsStore.shared)
    ) {
        self.recording = recording
        self.display = display
        self.export = export
        self.classification = classification
    }
}
