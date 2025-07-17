//
//  ExportSettingsProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
import Foundation

protocol ExportSettingsProtocol: ObservableObject {
    var defaultExportFormat: ExportFormat { get set }
    var includeRawCoordinates: Bool { get set }
    var defaultExportFileNamePrefix: String { get set }
}

