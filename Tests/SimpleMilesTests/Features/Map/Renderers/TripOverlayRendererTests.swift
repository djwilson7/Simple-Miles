//
//  TripOverlayRendererTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

// TripOverlayRendererTests.swift
import XCTest
import MapKit
@testable import SimpleMiles

final class TripOverlayRendererTests: XCTestCase {
    func testPolylinesAreGeneratedCorrectly() {
        let segments = [
            TripSegmentModel(
                startTime: Date(),
                endTime: Date().addingTimeInterval(120),
                startCoordinate: CoordinateModel(latitude: 37.0, longitude: -122.0),
                endCoordinate: CoordinateModel(latitude: 37.1, longitude: -122.1),
                distance: 1000
            ),
            TripSegmentModel(
                startTime: Date(),
                endTime: Date().addingTimeInterval(240),
                startCoordinate: CoordinateModel(latitude: 38.0, longitude: -123.0),
                endCoordinate: CoordinateModel(latitude: 38.1, longitude: -123.1),
                distance: 2000
            )
        ]

        let polylines = TripOverlayRenderer.polylines(from: segments)
        XCTAssertEqual(polylines.count, 2)

        let first = polylines[0]
        XCTAssertEqual(first.pointCount, 2)
    }

    func testEmptyInputReturnsEmptyOverlayList() {
        let polylines = TripOverlayRenderer.polylines(from: [])
        XCTAssertTrue(polylines.isEmpty)
    }
}
