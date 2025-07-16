//
//  JSONTripWriter.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class JSONTripWriter {
    static func export(from trips: [TripSessionModel]) -> URL? {
        guard !trips.isEmpty else { return nil }

        let schemaObjects = trips.map { JSONExportSchema(from: $0) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(schemaObjects)
            let jsonString = String(decoding: data, as: UTF8.self)
            return FileExportWriter.write(content: jsonString, fileName: "SimpleMiles_Backup", fileExtension: "json")
        } catch {
            print("JSON encoding failed: \(error)")
            return nil
        }
    }
}
