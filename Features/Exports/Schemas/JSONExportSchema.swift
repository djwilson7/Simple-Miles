//
//  JSONExportSchema.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation

struct JSONExportSchema {
    let id: UUID
    let startTime: String
    let endTime: String?
    let distance: Double
    let tripType: String
    let path: [Coordinate]

    struct Coordinate: Encodable {
        let latitude: Double
        let longitude: Double
    }

    init(from model: TripSessionModel) {
        self.id = model.id
        self.startTime = Self.isoFormatter.string(from: model.startTime)
        self.endTime = model.endTime.map { Self.isoFormatter.string(from: $0) }
        self.distance = model.distance
        self.tripType = model.tripType.rawValue
        self.path = model.path.map {
            Coordinate(latitude: $0.latitude, longitude: $0.longitude)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(distance, forKey: .distance)
        try container.encode(tripType, forKey: .tripType)
        try container.encode(path, forKey: .path)
    }

    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, distance, tripType, path
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

extension JSONExportSchema: Encodable {}
