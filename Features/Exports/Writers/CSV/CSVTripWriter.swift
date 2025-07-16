//
//  CSVTripWriter.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class CSVTripWriter {
    static func export(from trips: [TripSessionModel]) -> URL? {
        guard !trips.isEmpty else { return nil }

        let schemaRows = trips.map { CSVExportSchema(from: $0) }
        let headerLine = CSVExportSchema.headers.joined(separator: ",")
        let rowLines = schemaRows.map { $0.toCSVRow() }

        let csvContent = ([headerLine] + rowLines).joined(separator: "\n")

        return FileExportWriter.write(
            content: csvContent,
            fileName: "trip_summary",
            fileExtension: "csv"
        )
    }
}
