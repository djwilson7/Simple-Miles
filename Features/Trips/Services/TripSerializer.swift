//
//  TripSerializer.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation
import CoreLocation

struct TripSerializer {
    private static let filename = "Trips.json"

    private static var fileURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(filename)
    }

    // MARK: - Public Save/Load (default location)
    static func save(_ trips: [TripModel]) throws {
        guard let url = fileURL else {
            throw NSError(domain: "TripSerializer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"])
        }
        try save(trips, to: url)
    }

    static func load() throws -> [TripModel] {
        guard let url = fileURL else { return [] }
        return try load(from: url)
    }

    // MARK: - Overload for custom testing paths
    static func save(_ trips: [TripModel], to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(trips)
        try data.write(to: url)
    }

    static func load(from url: URL) throws -> [TripModel] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return []
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([TripModel].self, from: data)
    }
    
    private static func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static func deleteAll() throws {
        let url = getDocumentsDirectory().appendingPathComponent("Trips.json")
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
