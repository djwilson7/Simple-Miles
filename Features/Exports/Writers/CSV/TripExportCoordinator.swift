//
//  TripExportCoordinator.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class TripExportCoordinator: CSVExportingProtocol {
    func export(from trips: [TripSessionModel]) -> URL? {
        guard
            let summaryURL = CSVTripWriter.export(from: trips),
            let coordinatesURL = CSVCoordinateWriter.export(from: trips)
        else {
            print("❌ Failed to generate CSV files")
            return nil
        }

        let zipName = "TripExport_\(formattedDateStamp())"
        return FileZipper.zipFiles([summaryURL, coordinatesURL], zipName: zipName)
    }

    private func formattedDateStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter.string(from: Date())
    }
}

