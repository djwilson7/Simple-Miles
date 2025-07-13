//
//  TripStorageServiceTests.swift
//  Simple MilesTests
//
//  Created by Invictus Maneo on 7/12/25.
//

import XCTest
@testable import SimpleMiles
import CoreLocation

final class TripStorageServiceTests: XCTestCase {
    
    var service: TripStorageService!
    
    override func setUpWithError() throws {
        try TripSerializer.deleteAll() // Ensure clean slate
        service = TripStorageService()
    }

    override func tearDownWithError() throws {
        try TripSerializer.deleteAll()
        service = nil
    }

    func createMockTrip(type: TripType = .business) -> TripModel {
        return TripModel(
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            tripType: type,
            distance: 1500,
            route: [Coordinate(latitude: 37.0, longitude: -122.0)]
        )
    }

    func testInitialLoadEmpty() throws {
        XCTAssertEqual(service.trips.count, 0)
    }

    func testAddTripPersistsCorrectly() throws {
        let trip = createMockTrip()
        service.add(trip)

        let reloaded = TripStorageService().trips
        let match = reloaded.first(where: { $0.id == trip.id })
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.tripType, trip.tripType)
        XCTAssertEqual(match?.distance, trip.distance)
    }

    func testUpdateTripReflectsChanges() throws {
        var trip = createMockTrip(type: .personal)
        service.add(trip)

        trip.tripType = .business
        service.update(trip)

        let updatedTrip = TripStorageService().trips.first { $0.id == trip.id }
        XCTAssertEqual(updatedTrip?.tripType, .business)
    }

    func testDeleteTripRemovesTrip() throws {
        let trip = createMockTrip()
        service.add(trip)
        service.delete(id: trip.id)

        let reloaded = TripStorageService().trips
        XCTAssertFalse(reloaded.contains(trip))
    }

    func testTripFilterByTypeBusiness() throws {
        service.add(createMockTrip(type: .business))
        service.add(createMockTrip(type: .personal))
        service.add(createMockTrip(type: .business))

        let businessTrips = service.filtered(by: TripType.business)
        XCTAssertTrue(businessTrips.allSatisfy { $0.tripType == TripType.business })
    }

    func testTripFilterByTypePersonal() throws {
        service.add(createMockTrip(type: .personal))
        service.add(createMockTrip(type: .personal))
        service.add(createMockTrip(type: .business))

        let personalTrips = service.filtered(by: TripType.personal)
        XCTAssertTrue(personalTrips.allSatisfy { $0.tripType == TripType.personal })
    }

    func testTripFilterAllTypes() throws {
        service.add(createMockTrip(type: TripType.business))
        service.add(createMockTrip(type: TripType.personal))
        service.add(createMockTrip(type: TripType.unclassified))

        let allTrips = service.filtered(by: nil)
        XCTAssertEqual(allTrips.count, 3)
    }

    func testLoadInvalidDataHandlesGracefully() throws {
        let invalidDataURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Trips.json")
        try "invalid json".write(to: invalidDataURL, atomically: true, encoding: .utf8)

        let loaded = TripStorageService().trips
        XCTAssertEqual(loaded.count, 0)
    }
    
    // MARK: - Edge Case & Robustness Tests

    func testAddTripWithEmptyRoutePersistsCorrectly() throws {
        var trip = createMockTrip()
        trip.route = []
        service.add(trip)
        
        let reloaded = TripStorageService().trips
        let saved = reloaded.first { $0.id == trip.id }
        
        XCTAssertNotNil(saved)
        XCTAssertEqual(saved?.route.count, 0)
    }

    func testAddingDuplicateTripDoesNotCreateDuplicate() throws {
        let trip = createMockTrip()
        service.add(trip)
        service.add(trip) // Attempt to re-add same trip
        
        let reloaded = TripStorageService().trips
        let duplicates = reloaded.filter { $0.id == trip.id }
        
        XCTAssertEqual(duplicates.count, 1)
    }

    func testUpdateOnlyAffectsSpecifiedTrip() throws {
        let trip1 = createMockTrip()
        var trip2 = createMockTrip()
        service.add(trip1)
        service.add(trip2)

        trip2.tripType = .personal
        service.update(trip2)

        let reloaded = TripStorageService().trips
        let updated = reloaded.first { $0.id == trip2.id }
        let untouched = reloaded.first { $0.id == trip1.id }

        XCTAssertEqual(updated?.tripType, .personal)
        XCTAssertEqual(untouched?.tripType, trip1.tripType)
    }

    func testDeletingNonexistentTripDoesNotCrash() throws {
        let originalCount = service.trips.count
        let randomID = UUID()
        
        service.delete(id: randomID)
        
        let afterDeleteCount = TripStorageService().trips.count
        XCTAssertEqual(originalCount, afterDeleteCount)
    }

    func testTripWithLongUserNotesPersists() throws {
        var trip = createMockTrip()
        trip.userNotes = String(repeating: "Note ", count: 1000)
        service.add(trip)
        
        let reloaded = TripStorageService().trips
        let saved = reloaded.first { $0.id == trip.id }
        
        XCTAssertEqual(saved?.userNotes, trip.userNotes)
    }

    func testFilterReturnsEmptyWhenNoMatch() throws {
        service.add(createMockTrip(type: .business))
        let filtered = service.filtered(by: .personal)
        
        XCTAssertTrue(filtered.isEmpty)
    }

}
