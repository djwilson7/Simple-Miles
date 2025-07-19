//
//  LiveLocationMapView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

//
//  LiveLocationMapView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

//
//  LiveLocationMapView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import SwiftUI
import MapKit

struct LiveLocationMapView: UIViewRepresentable {
    @ObservedObject var viewModel: MapViewModel
    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isUserInteractionEnabled = false

        mapView.layer.cornerRadius = 16
        mapView.layer.masksToBounds = true

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        drawLivePath(on: uiView)

        // Always re-enable follow mode after UI updates
        if uiView.userTrackingMode != .follow {
            uiView.setUserTrackingMode(.follow, animated: true)
        }

        if let userLocation = uiView.userLocation.location {
            print("[LiveLocationMapView] - user location: ", userLocation.coordinate)
        } else {
            print("[LiveLocationMapView] - user location is nil")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private func drawLivePath(on mapView: MKMapView) {
        mapView.removeOverlays(mapView.overlays)

        let polyline = TripOverlayRenderer.polyline(from: viewModel.pathPoints)
        mapView.addOverlay(polyline)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemGreen
            renderer.lineWidth = 5
            return renderer
        }
    }
}
