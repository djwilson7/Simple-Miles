//
//  MockTripSegmentRecorder.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import CoreLocation
@testable import SimpleMiles

final class MockTripSegmentRecorder: TripSegmentRecordingProtocol {
    private(set) var didBeginSegment = false
    private(set) var didCompleteSegment = false
    private(set) var didReset = false

    var mockSegments: [TripSegmentModel] = []

    var recordedSegments: [TripSegmentModel] {
        mockSegments
    }

    func beginSegment(at coordinate: CLLocationCoordinate2D) {
        didBeginSegment = true
    }

    func completeSegment(at coordinate: CLLocationCoordinate2D, timestamp: Date) {
        didCompleteSegment = true
    }

    func reset() {
        didReset = true
    }
}
