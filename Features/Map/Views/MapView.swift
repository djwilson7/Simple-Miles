//
//  MapView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapView: UIViewRepresentable {
    @Binding var segments: [TripSegmentModel]

    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isRotateEnabled = false
        mapView.isPitchEnabled = false
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        updateMapOverlays(on: uiView)
    }

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator()
    }

    private func updateMapOverlays(on mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)
        
        let overlays = TripOverlayRenderer.polylines(from: segments)

        mapView.addOverlays(overlays)
        if let bounds = calculateVisibleRegion(from: segments) {
            mapView.setVisibleMapRect(bounds, edgePadding: UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40), animated: false)
        }
    }

    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemBlue
            renderer.lineWidth = 4
            return renderer
        }
    }
    
    private func calculateVisibleRegion(from segments: [TripSegmentModel]) -> MKMapRect? {
        let coordinates = segments.flatMap { [$0.startCoordinate.clLocationCoordinate, $0.endCoordinate.clLocationCoordinate] }
        guard !coordinates.isEmpty else { return nil }

        let mapPoints = coordinates.map { MKMapPoint($0) }
        var rect = MKMapRect.null
        for point in mapPoints {
            rect = rect.union(MKMapRect(origin: point, size: MKMapSize(width: 0.1, height: 0.1)))
        }
        return rect
    }
}

#Preview {
    MapView(segments: .constant([
        TripSegmentModel(
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            startCoordinate: CoordinateModel(
                latitude: 37.7749,
                longitude: -122.4194
            ),
            endCoordinate: CoordinateModel(
                latitude: 37.7849,
                longitude: -122.4094
            ),
            distance: 1000
        )
    ]))
    .edgesIgnoringSafeArea(.all)
}


