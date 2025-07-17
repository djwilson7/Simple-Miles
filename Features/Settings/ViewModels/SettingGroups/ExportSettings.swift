//
//  ExportSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class ExportSettings: ExportSettingsProtocol {
    @Published var defaultExportFormat: ExportFormat {
        didSet { store.set(.defaultExportFormat, value: defaultExportFormat.rawValue) }
    }

    @Published var includeRawCoordinates: Bool {
        didSet { store.set(.includeRawCoordinates, value: includeRawCoordinates) }
    }

    @Published var defaultExportFileNamePrefix: String {
        didSet { store.set(.defaultExportFileNamePrefix, value: defaultExportFileNamePrefix) }
    }

    private let store: SettingsStoring

    init(store: SettingsStoring) {
        self.store = store
        defaultExportFormat = store.getEnum(.defaultExportFormat, default: .csv)
        includeRawCoordinates = store.getBool(.includeRawCoordinates, default: false)
        defaultExportFileNamePrefix = store.getString(.defaultExportFileNamePrefix, default: "MilesExport_")
    }
}
