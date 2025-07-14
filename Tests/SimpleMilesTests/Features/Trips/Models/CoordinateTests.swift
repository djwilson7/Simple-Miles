//
//  CoordinateTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import XCTest
import CoreLocation
@testable import SimpleMiles

final class CoordinateTests: XCTestCase {

    func testInitWithLatitudeLongitude() {
        let latitude: Double = 37.7749
        let longitude: Double = -122.4194
        let coordinate = CoordinateModel(latitude: latitude, longitude: longitude)
        XCTAssertEqual(coordinate.latitude, latitude)
        XCTAssertEqual(coordinate.longitude, longitude)
    }

    func testInitFromCLLocationCoordinate2D() {
        let clLocation = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let coordinate = CoordinateModel(from: clLocation)
        XCTAssertEqual(coordinate.latitude, clLocation.latitude)
        XCTAssertEqual(coordinate.longitude, clLocation.longitude)
    }

    func testConversionToCLLocationCoordinate2D() {
        let latitude: Double = 48.8566
        let longitude: Double = 2.3522
        let coordinate = CoordinateModel(latitude: latitude, longitude: longitude)
        let clLocation = coordinate.clLocationCoordinate
        XCTAssertEqual(clLocation.latitude, latitude)
        XCTAssertEqual(clLocation.longitude, longitude)
    }

    func testHashableAndEquatable() {
        let a = CoordinateModel(latitude: 10.0, longitude: 20.0)
        let b = CoordinateModel(latitude: 10.0, longitude: 20.0)
        let c = CoordinateModel(latitude: 10.0, longitude: 20.1)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)

        var set = Set<CoordinateModel>()
        set.insert(a)
        set.insert(b)
        XCTAssertEqual(set.count, 1, "Duplicate coordinates should not increase set size")
    }

    func testCodableRoundTrip() throws {
        let coordinate = CoordinateModel(latitude: -33.8688, longitude: 151.2093)
        let encoder = JSONEncoder()
        let data = try encoder.encode(coordinate)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CoordinateModel.self, from: data)
        XCTAssertEqual(decoded, coordinate)
    }
}
