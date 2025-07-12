//
//  TripModel.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation
import CoreLocation

struct TripModel: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let distance: Double
    let route: [CLLocationCoordinate2D]
    let classification: TripType

    enum TripType: String, Codable {
        case business, personal, unclassified
    }
}
