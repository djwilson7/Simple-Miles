//
//  MockTripExportViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

// MARK: - MockTripExportViewModel.swift

import Foundation
@testable import SimpleMiles

final class MockTripExportViewModel: TripExportViewModelProtocol {
    var store: TripSessionStoringProtocol = MockTripSessionStore()

    var exportedCSVURL: URL? = URL(string: "mock://csv")
    var exportedJSONURL: URL? = URL(string: "mock://json")

    func generateCSVExport() -> URL? {
        return exportedCSVURL
    }

    func generateJSONBackup() -> URL? {
        return exportedJSONURL
    }
}

