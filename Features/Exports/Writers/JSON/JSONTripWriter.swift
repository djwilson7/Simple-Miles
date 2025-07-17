//
//  JSONTripWriter.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

final class JSONTripWriter: JSONExportingProtocol {
    func export(from trips: [TripSessionModel]) -> URL? {
        print("[JSONTripWriter] export triggered with \(trips.count) trip(s)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard !trips.isEmpty else {
            print("[JSONTripWriter] export aborted – empty trip list") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return nil
        }

        let schemaObjects = trips.map { JSONExportSchema(from: $0) }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        do {
            let data = try encoder.encode(schemaObjects)
            let jsonString = String(decoding: data, as: UTF8.self)
            return FileExportWriter.write(content: jsonString, fileName: "SimpleMiles_Backup", fileExtension: "json")
        } catch {
            print("[JSONTripWriter] JSON encoding failed: \(error)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return nil
        }
    }
}
