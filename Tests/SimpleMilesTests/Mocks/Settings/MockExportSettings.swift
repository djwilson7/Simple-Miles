//
//  MockExportSettings.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockExportSettings: ExportSettingsProtocol {
    var defaultExportFormat: ExportFormat = .csv
    var includeRawCoordinates: Bool = true
    var defaultExportFileNamePrefix: String = "Test_"
}
