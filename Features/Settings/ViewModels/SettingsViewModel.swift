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
    @Published var recording: RecordingSettings
    @Published var display: DisplaySettings
    @Published var export: ExportSettings
    @Published var classification: ClassificationSettings

    init(store: SettingsStoring = SettingsStore.shared) {
        self.recording = RecordingSettings(store: store)
        self.display = DisplaySettings(store: store)
        self.export = ExportSettings(store: store)
        self.classification = ClassificationSettings(store: store)
    }
}
