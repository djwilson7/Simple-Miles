//
//  TripHelper.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation
import CoreLocation

struct TripHelper {
    static func formatDistance(_ distance: Double) -> String {
        return String(format: "%.2f miles", distance)
    }

    static func smoothRoute(_ coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        // Optional smoothing logic
        return coordinates
    }
}
