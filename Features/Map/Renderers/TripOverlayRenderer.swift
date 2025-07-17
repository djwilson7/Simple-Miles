//
//  TripOverlayRenderer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//
import MapKit

struct TripOverlayRenderer {
    static func polyline(from path: [CoordinateModel]) -> MKPolyline {
        let coordinates = path.map { $0.clLocationCoordinate }
        return MKPolyline(coordinates: coordinates, count: coordinates.count)
    }
}

