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
    let segments: [Segment]

    struct Segment: Encodable {
        let id: UUID
        let startTime: String
        let endTime: String
        let distance: Double
        let start: Coordinate
        let end: Coordinate
    }

    struct Coordinate: Encodable {
        let latitude: Double
        let longitude: Double
    }

    init(from model: TripSessionModel) {
        self.id = model.id
        self.startTime = Self.isoFormatter.string(from: model.startTime)
        self.endTime = model.endTime.map { Self.isoFormatter.string(from: $0) } ?? ""
        self.distance = model.distance
        self.tripType = model.tripType.rawValue
        self.segments = model.segments.map {
            Segment(
                id: $0.id,
                startTime: Self.isoFormatter.string(from: $0.startTime),
                endTime: Self.isoFormatter.string(from: $0.endTime),
                distance: $0.distance,
                start: Coordinate(latitude: $0.startCoordinate.latitude, longitude: $0.startCoordinate.longitude),
                end: Coordinate(latitude: $0.endCoordinate.latitude, longitude: $0.endCoordinate.longitude)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(distance, forKey: .distance)
        try container.encode(tripType, forKey: .tripType)
        try container.encode(segments, forKey: .segments)  // if empty, encodes as []
    }

    enum CodingKeys: String, CodingKey {
        case id, startTime, endTime, distance, tripType, segments
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}

extension JSONExportSchema: Encodable {}
