//
//  Coordinate.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation
import CoreLocation

struct CoordinateModel: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    // Convert to CLLocationCoordinate2D (for MapKit or overlays)
    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    // Convert from CLLocationCoordinate2D
    init(from clLocation: CLLocationCoordinate2D) {
        self.latitude = clLocation.latitude
        self.longitude = clLocation.longitude
    }

    // Default initializer
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
