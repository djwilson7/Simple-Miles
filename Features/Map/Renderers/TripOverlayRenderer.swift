//
//  TripOverlayRenderer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//
import MapKit

struct TripOverlayRenderer {
    static func polylines(from segments: [TripSegmentModel]) -> [MKPolyline] {
        segments.map { segment in
            let coords = [
                segment.startCoordinate.clLocationCoordinate,
                segment.endCoordinate.clLocationCoordinate
            ]
            return MKPolyline(coordinates: coords, count: coords.count)
        }
    }
}
