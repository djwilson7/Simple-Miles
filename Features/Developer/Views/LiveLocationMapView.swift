//
//  LiveLocationMapView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import SwiftUI
import MapKit

struct LiveLocationMapView: UIViewRepresentable {
    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow  // ← enables live tracking
        mapView.isUserInteractionEnabled = false

        mapView.layer.cornerRadius = 16
        mapView.layer.masksToBounds = true

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let userLocation = uiView.userLocation.location {
            //print("[LiveLocationMapView] - user location: ", userLocation.coordinate)
        } else {
            //print("LiveLocationMapView - user location is nil")
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        // Optional: log or extend behavior
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            //print("[LiveLocationMapView-Coordinator] - User Coordinates : \(userLocation.coordinate)")
        }
    }
}
