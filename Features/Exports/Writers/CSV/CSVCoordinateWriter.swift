//
//  CSVCoordinateWriter.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

enum CSVCoordinateWriter {
    static func export(from trips: [TripSessionModel]) -> URL? {
        let headers = "tripID,flattenedPath"
        var rows: [String] = [headers]

        for trip in trips {
            let tripID = trip.id.uuidString
            let path = trip.segments
                .flatMap { [$0.startCoordinate, $0.endCoordinate] }
                .map { "\($0.latitude),\($0.longitude)" }
                .joined(separator: ";")

            rows.append("\(tripID),\(path)")
        }

        let csvString = rows.joined(separator: "\n")
        return FileExportWriter.write(content: csvString, fileName: "trip_coordinates", fileExtension: "csv")
    }
}
