//
//  JSONExportSchemaTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
@testable import SimpleMiles

final class JSONExportSchemaTests: XCTestCase {
    func testInitializationMapsTripModelToSchemaCorrectly() {
        let trip = TripSessionModel.mock()
        let schema = JSONExportSchema(from: trip)

        XCTAssertEqual(schema.id, trip.id)
        XCTAssertEqual(schema.tripType, trip.tripType.rawValue)
        XCTAssertEqual(schema.segments.count, trip.segments.count)
    }

    func testEncodableOutputIncludesAllSegments() throws {
        let trip = TripSessionModel.mock()
        let schema = JSONExportSchema(from: trip)

        let encoder = JSONEncoder()
        let data = try encoder.encode(schema)
        let json = String(decoding: data, as: UTF8.self)

        XCTAssertTrue(json.contains(schema.tripType))
        XCTAssertTrue(json.contains(schema.id.uuidString))
    }

    func testEncodesStartAndEndTimestampsAsISO8601() {
        let trip = TripSessionModel.mock()
        let schema = JSONExportSchema(from: trip)

        XCTAssertTrue(schema.startTime.contains("T"), "Should encode as ISO8601 datetime")
    }
    
    func testEncodingHandlesNilEndTime() throws {
        let trip = TripSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: nil, // explicitly nil to test placeholder behavior
            distance: 100,
            segments: []
        )
        
        let schema = JSONExportSchema(from: trip)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(schema)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"endTime\" : \"\""), "endTime should serialize as an empty string when nil")
    }


    func testCoordinatesEncodeWithExpectedPrecision() throws {
        let segment = TripSegmentModel.mock(
            startCoordinate: CoordinateModel(latitude: 51.123456789, longitude: -0.123456789),
            endCoordinate: CoordinateModel(latitude: 51.987654321, longitude: -0.987654321)
        )
        let trip = TripSessionModel.mock(segments: [segment])
        let schema = JSONExportSchema(from: trip)

        let data = try JSONEncoder().encode(schema)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("51.123456"), "Should encode latitude with precision")
        XCTAssertTrue(json.contains("-0.987654"), "Should encode longitude with precision")
    }

    func testEncodingTripWithNoSegmentsReturnsEmptyArray() throws {
        let trip = TripSessionModel.mock(segments: [])
        let schema = JSONExportSchema(from: trip)

        let data = try JSONEncoder().encode(schema)
        let json = String(data: data, encoding: .utf8)!

        XCTAssertTrue(json.contains("\"segments\":[]"), "Should encode empty segment array")
    }

}
