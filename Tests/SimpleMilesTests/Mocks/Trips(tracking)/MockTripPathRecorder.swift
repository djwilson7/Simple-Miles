//
//  MockTripPathRecorder.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/18/25.
//

import Foundation
import CoreLocation
@testable import SimpleMiles

final class MockTripPathRecorder: TripPathRecordingProtocol {
    private(set) var coordinates: [CoordinateModel] = []
    private(set) var didReset = false
    private(set) var appendedLocations: [CLLocationCoordinate2D] = []

    func append(_ location: CLLocationCoordinate2D) {
        appendedLocations.append(location)
        let model = CoordinateModel(latitude: location.latitude, longitude: location.longitude)
        coordinates.append(model)
    }

    func reset() {
        didReset = true
        coordinates.removeAll()
    }
}

