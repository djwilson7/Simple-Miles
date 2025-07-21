//
//  Coordinate.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation
import CoreLocation

enum CoordinateState: String, Codable {
    case active
    case paused
}

struct CoordinateModel: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let state: CoordinateState

    var clLocationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(latitude: Double, longitude: Double, state: CoordinateState = .active) {
        self.latitude = latitude
        self.longitude = longitude
        self.state = state
    }

    init(from clLocation: CLLocationCoordinate2D, state: CoordinateState = .active) {
        self.latitude = clLocation.latitude
        self.longitude = clLocation.longitude
        self.state = state
    }
}
