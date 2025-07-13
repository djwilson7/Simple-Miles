//
//  TripSerializerTests.swift
//  Simple MilesTests
//
//  Created by Invictus Maneo on 7/12/25.
//
import XCTest
@testable import SimpleMiles
import CoreLocation

final class TripSerializerTests: XCTestCase {
    
    var testTrip: TripModel!
    var testURL: URL!

    override func setUp() {
        super.setUp()
        
        testTrip = TripModel(
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            tripType: .business,
            distance: 1500,
            route: [
                Coordinate(latitude: 32.7767, longitude: -96.7970),
                Coordinate(latitude: 32.7800, longitude: -96.8000)
            ],
            averageSpeed: 45.0,
            userNotes: "Test trip",
            regionIdentifier: "Dallas"
        )
        
        // Create a temporary file for I/O
        let tempDirectory = FileManager.default.temporaryDirectory
        testURL = tempDirectory.appendingPathComponent("test_trip.json")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: testURL)
        testTrip = nil
        testURL = nil
        super.tearDown()
    }

    // 1. Save a valid TripModel to disk
    func testSaveTripSuccessfully() {
        XCTAssertNoThrow(try TripSerializer.save([testTrip], to: testURL))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testURL.path))
    }

    // 2. Load a valid TripModel from disk
    func testLoadTripSuccessfully() {
        try? TripSerializer.save([testTrip], to: testURL)
        do {
            let loadedTrips = try TripSerializer.load(from: testURL)
            XCTAssertEqual(loadedTrips.count, 1)
            XCTAssertEqual(loadedTrips.first?.id, testTrip.id)
        } catch {
            XCTFail("Loading trip failed: \(error)")
        }
    }

    // 3. Save to an invalid path
    func testSaveTripToInvalidPath() {
        let invalidURL = URL(fileURLWithPath: "/invalid/path/test.json")
        XCTAssertThrowsError(try TripSerializer.save([testTrip], to: invalidURL))
    }

    // 4. Load from a non-existent file
    func testLoadTripFromInvalidPath() {
        let nonExistentURL = testURL.deletingLastPathComponent().appendingPathComponent("doesnotexist.json")
        do {
            let result = try TripSerializer.load(from: nonExistentURL)
            XCTAssertTrue(result.isEmpty)
        } catch {
            XCTFail("Expected empty result, got error: \(error)")
        }
    }

    // 5. Load from corrupted JSON
    func testLoadMalformedJSON() {
        let invalidData = "Not a JSON string".data(using: .utf8)!
        FileManager.default.createFile(atPath: testURL.path, contents: invalidData, attributes: nil)
        XCTAssertThrowsError(try TripSerializer.load(from: testURL))
    }
}
