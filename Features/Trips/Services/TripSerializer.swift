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

    static func save(_ trips: [TripModel]) throws {
        print("[TripSerializer] save triggered to default location") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let url = fileURL else {
            print("[TripSerializer] save failed – invalid fileURL") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            throw NSError(domain: "TripSerializer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid file URL"])
        }
        try save(trips, to: url)
    }

    static func load() throws -> [TripModel] {
        print("[TripSerializer] load triggered from default location") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let url = fileURL else {
            print("[TripSerializer] load failed – no valid fileURL") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return []
        }
        return try load(from: url)
    }

    static func save(_ trips: [TripModel], to url: URL) throws {
        print("[TripSerializer] save triggered to custom URL: \(url)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(trips)
        try data.write(to: url)
    }

    static func load(from url: URL) throws -> [TripModel] {
        print("[TripSerializer] load triggered from URL: \(url)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("[TripSerializer] no file found at URL") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
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
        print("[TripSerializer] deleteAll triggered at path: \(url.path)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
