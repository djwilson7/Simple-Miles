//
//  MockCSVExporter.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockCSVExporter: CSVExportingProtocol {
    var exportCalled = false
    var exportedTrips: [TripSessionModel] = []
    var exportURLToReturn: URL? = URL(string: "file://mock.csv.bundle")

    func export(from trips: [TripSessionModel]) -> URL? {
        exportCalled = true
        exportedTrips = trips
        return exportURLToReturn
    }
}
