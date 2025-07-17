//
//  TripPathRecorder.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
import CoreLocation

final class TripPathRecorder {
    private(set) var coordinates: [CoordinateModel] = []

    func append(_ location: CLLocationCoordinate2D) {
        let model = CoordinateModel(latitude: location.latitude, longitude: location.longitude)
        coordinates.append(model)
        print("[TripPathRecorder] tick location: (\(model.latitude), \(model.longitude))") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
    }

    func reset() {
        print("[TripPathRecorder] reset triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        coordinates.removeAll()
    }
}
