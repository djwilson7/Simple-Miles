//
//  TripSessionStoreTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
import CoreData
@testable import SimpleMiles

final class TripSessionStoreTests: XCTestCase {

    var context: NSManagedObjectContext!
    var sut: TripSessionStore!

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
        sut = TripSessionStore(context: context)
    }

    func testSaveSingleSessionPersistsCorrectly() {
        let session = makeTestSession()
        sut.save(session)

        let fetched = sut.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, session.id)
        XCTAssertEqual(fetched.first?.distance, session.distance)
    }

    func testDeleteRemovesCorrectSession() {
        let session1 = makeTestSession()
        let session2 = makeTestSession()

        sut.save(session1)
        sut.save(session2)

        sut.delete(sessionID: session1.id)
        let remaining = sut.fetchAll()

        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.id, session2.id)
    }

    func testFetchEmptyReturnsEmptyArray() {
        let results = sut.fetchAll()
        XCTAssertTrue(results.isEmpty)
    }

    func testMultipleSavesPersistAllSessions() {
        let session1 = makeTestSession()
        let session2 = makeTestSession()

        sut.save(session1)
        sut.save(session2)

        let results = sut.fetchAll()
        XCTAssertEqual(results.count, 2)
    }

    func testSavingSameSessionTwiceCreatesDuplicates() {
        let session = makeTestSession()
        sut.save(session)
        sut.save(session)

        let results = sut.fetchAll()
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results.filter { $0.id == session.id }.count, 2)
    }

    // MARK: - Helpers

    private func makeTestSession() -> TripSessionModel {
        let segment = TripSegmentModel(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(60),
            startCoordinate: .init(latitude: 10, longitude: 10),
            endCoordinate: .init(latitude: 20, longitude: 20),
            distance: 150
        )
        return TripSessionModel(
            id: UUID(),
            startTime: Date(),
            endTime: Date().addingTimeInterval(180),
            distance: 150,
            segments: [segment]
        )
    }
}
