//
//  TripExportViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class TripExportViewModel: ObservableObject {
    var store: TripSessionStoringProtocol {
        return self._store
    }
    
    private let _store: TripSessionStoringProtocol

    init(store: TripSessionStoringProtocol = TripSessionStore()) {
        self._store = store
    }

    func generateCSVExport() -> URL? {
        return TripExportCoordinator.exportCSVBundle(from: store.fetchAll())
    }

    func generateJSONBackup() -> URL? {
        return JSONTripWriter.export(from: store.fetchAll())
    }
}
