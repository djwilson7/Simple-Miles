//
//  TripOverlayRenderer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import MapKit

struct TripOverlayRenderer {
    static func segmentedPolylines(from path: [CoordinateModel]) -> [MKPolyline] {
        var result: [MKPolyline] = []
        var current: [CLLocationCoordinate2D] = []
        var lastState: CoordinateState?

        for point in path {
            if lastState == nil || point.state == lastState {
                current.append(point.clLocationCoordinate)
            } else {
                if current.count > 1 {
                    result.append(MKPolyline(coordinates: current, count: current.count))
                }
                current = [point.clLocationCoordinate]
            }
            lastState = point.state
        }

        if current.count > 1 {
            result.append(MKPolyline(coordinates: current, count: current.count))
        }

        return result
    }

    static func renderer(for polyline: MKPolyline, state: CoordinateState) -> MKPolylineRenderer {
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.lineWidth = 4

        switch state {
        case .active:
            renderer.strokeColor = .systemBlue
        case .paused:
            renderer.strokeColor = .systemBlue
            renderer.lineDashPattern = [4, 4]
        }

        return renderer
    }
}
