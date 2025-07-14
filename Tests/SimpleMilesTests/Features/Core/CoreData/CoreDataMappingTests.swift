//
//  CoreDataMappingTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
import CoreData
@testable import SimpleMiles

final class CoreDataMappingTests: XCTestCase {

    var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        let container = NSPersistentContainer(name: "SimpleMilesModel")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        context = container.viewContext
    }

    func testRoundTripConversionWithFullData() {
        let segment = TripSegmentModel(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(60),
            startCoordinate: .init(latitude: 10, longitude: 10),
            endCoordinate: .init(latitude: 11, longitude: 11),
            distance: 100
        )
        let original = TripSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(300),
            distance: 100,
            segments: [segment]
        )

        let stored = CDTripSession(from: original, context: context)
        let roundTrip = stored.toModel()

        XCTAssertEqual(roundTrip.id, original.id)
        XCTAssertEqual(roundTrip.distance, 100)
        XCTAssertEqual(roundTrip.segments.count, 1)
        XCTAssertEqual(roundTrip.segments.first?.distance, 100)
    }

    func testTripSessionInitWithNilOptionalFields() {
        let model = TripSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: nil,
            distance: 0,
            segments: []
        )

        let stored = CDTripSession(from: model, context: context)
        XCTAssertNil(stored.endTime)
        XCTAssertNotNil(stored.id)
    }

    func testToModelHandlesNilUUIDOrStartTime() {
        let entity = CDTripSession(context: context)
        entity.id = nil
        entity.startTime = nil
        entity.endTime = Date()
        entity.distance = 0

        let result = entity.toModel()

        XCTAssertNotNil(result.id)
        XCTAssertNotEqual(result.startTime, .distantFuture) // using .distantPast as fallback
    }

    func testSegmentConversionIncludesDistance() {
        let segment = TripSegmentModel(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            startCoordinate: .init(latitude: 1, longitude: 1),
            endCoordinate: .init(latitude: 2, longitude: 2),
            distance: 300
        )

        let model = TripSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(500),
            distance: 300,
            segments: [segment]
        )

        let stored = CDTripSession(from: model, context: context)
        XCTAssertEqual(stored.distance, 300)
    }

    func testCoordinateOrderingAndConversion() {
        let segment = CDTripSegment(context: context)
        segment.id = UUID()
        segment.startTime = Date()
        segment.endTime = Date()
        segment.distance = 100
        segment.avgSpeed = 2

        let coord1 = CDCoordinate(context: context)
        coord1.latitude = 1
        coord1.longitude = 1
        coord1.timestamp = Date()

        let coord2 = CDCoordinate(context: context)
        coord2.latitude = 2
        coord2.longitude = 2
        coord2.timestamp = Date().addingTimeInterval(10)

        segment.coordinates = NSSet(array: [coord2, coord1])
        let result = segment.toModel()

        XCTAssertEqual(result.startCoordinate.latitude, 1)
        XCTAssertEqual(result.endCoordinate.latitude, 2)
    }

    func testToModelEmptySegmentsFallbacks() {
        let segment = CDTripSegment(context: context)
        segment.id = UUID()
        segment.startTime = Date()
        segment.endTime = Date()
        segment.distance = 0
        segment.avgSpeed = 0
        segment.coordinates = NSSet() // empty

        let model = segment.toModel()
        XCTAssertEqual(model.startCoordinate.latitude, 0)
        XCTAssertEqual(model.endCoordinate.longitude, 0)
    }

    func testTripSegmentToModelMapsFieldsCorrectly() {
        let segment = CDTripSegment(context: context)
        let now = Date()
        segment.id = UUID()
        segment.startTime = now
        segment.endTime = now.addingTimeInterval(60)
        segment.avgSpeed = 10
        segment.distance = 600
        segment.coordinates = NSSet(array: [
            CDCoordinate(from: .init(latitude: 5, longitude: 5), segment: segment, context: context),
            CDCoordinate(from: .init(latitude: 10, longitude: 10), segment: segment, context: context)
        ])

        let model = segment.toModel()
        XCTAssertEqual(model.distance, 600)
        XCTAssertEqual(model.duration, 60)
    }

    func testCDCoordinateToModelMapsFieldsCorrectly() {
        let core = CDCoordinate(context: context)
        core.latitude = 37.0
        core.longitude = -122.0
        core.timestamp = Date()

        let model = core.toModel()
        XCTAssertEqual(model.latitude, 37.0)
        XCTAssertEqual(model.longitude, -122.0)
    }
}
