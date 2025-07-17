//
//  TripSegmentRecorderTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
import CoreLocation
@testable import SimpleMiles

final class TripSegmentRecorderTests: XCTestCase {
    private var recorder: TripSegmentRecorder!

    override func setUp() {
        recorder = TripSegmentRecorder()
    }

    func test_beginSegment_setsStartCoordinate() {
        let coord = CLLocationCoordinate2D(latitude: 10, longitude: 20)
        recorder.beginSegment(at: coord)
        // internal check via complete call
        recorder.completeSegment(at: coord, timestamp: Date())

        XCTAssertEqual(recorder.recordedSegments.count, 1)
    }

    func test_completeSegment_withoutBeginSegment_doesNothing() {
        recorder.completeSegment(at: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date())
        XCTAssertTrue(recorder.recordedSegments.isEmpty)
    }

    func test_completeSegment_appendsValidSegment() {
        let start = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        let end = CLLocationCoordinate2D(latitude: 0.01, longitude: 0.01)
        recorder.beginSegment(at: start)
        recorder.completeSegment(at: end, timestamp: Date())

        let segments = recorder.recordedSegments
        XCTAssertEqual(segments.count, 1)
        XCTAssertTrue(segments.first!.distance > 0)
    }

    func test_reset_clearsSegments() {
        let c = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        recorder.beginSegment(at: c)
        recorder.completeSegment(at: c, timestamp: Date())

        recorder.reset()
        XCTAssertTrue(recorder.recordedSegments.isEmpty)
    }
}
