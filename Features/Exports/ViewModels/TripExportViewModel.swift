//
//  TripExportViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class TripExportViewModel: TripExportViewModelProtocol {
    var store: TripSessionStoringProtocol { _store }

    private let _store: TripSessionStoringProtocol
    private let csvExporter: CSVExportingProtocol
    private let jsonExporter: JSONExportingProtocol

    init(
        store: TripSessionStoringProtocol = TripSessionStore(),
        csvExporter: CSVExportingProtocol = TripExportCoordinator(),
        jsonExporter: JSONExportingProtocol = JSONTripWriter()
    ) {
        self._store = store
        self.csvExporter = csvExporter
        self.jsonExporter = jsonExporter
    }

    func generateCSVExport() -> URL? {
        print("[TripExportViewModel] generateCSVExport triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return csvExporter.export(from: store.fetchAll())
    }

    func generateJSONBackup() -> URL? {
        print("[TripExportViewModel] generateJSONBackup triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return jsonExporter.export(from: store.fetchAll())
    }
}
