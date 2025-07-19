//
//  TripPathRecordingProtocol.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/18/25.
//

import Foundation
import CoreLocation

protocol TripPathRecordingProtocol: AnyObject {
    var coordinates: [CoordinateModel] { get }
    func append(_ location: CLLocationCoordinate2D)
    func reset()
}
