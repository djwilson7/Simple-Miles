// CameraUtility.swift
// A utility for camera fitting/path calculations shared by CameraManager and MapViewModel

import Foundation
import CoreLocation
import _MapKit_SwiftUI

struct CameraUtility {
    /// Returns a MapCamera that fits the given path with a specified vertical offset.
    static func cameraToFitPath(
        _ path: [CLLocationCoordinate2D],
        offset: CGFloat = 0.1,
        defaultLocation: CLLocationCoordinate2D? = nil
    ) -> MapCamera {
        guard !path.isEmpty else {
            let fallback = defaultLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return MapCamera(centerCoordinate: fallback, distance: 1500, heading: 0, pitch: 0)
        }
        
        var minLat = path[0].latitude
        var maxLat = path[0].latitude
        var minLon = path[0].longitude
        var maxLon = path[0].longitude
        
        for p in path {
            minLat = min(minLat, p.latitude)
            maxLat = max(maxLat, p.latitude)
            minLon = min(minLon, p.longitude)
            maxLon = max(maxLon, p.longitude)
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let verticalAnchorRatio = 0.3
        let shiftRatio = 0.3 - verticalAnchorRatio
        let latSpan = maxLat - minLat
        let verticalShiftDegrees = latSpan * shiftRatio

        let adjustedCenter = CLLocationCoordinate2D(
            latitude: centerLat - verticalShiftDegrees,
            longitude: centerLon
        )

        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        let horizontalPaddingFactor = 4.5
        let verticalPaddingFactor = 4.0 + Double(offset)
        let paddedLatDelta = latDelta * verticalPaddingFactor
        let paddedLonDelta = lonDelta * horizontalPaddingFactor
        let maxPaddedDelta = max(paddedLatDelta, paddedLonDelta)

        // Convert degrees to meters (approx.)
        let metersPerDegree = 111_000.0
        let boundingDistance = maxPaddedDelta * metersPerDegree
        let paddedDistance = boundingDistance

        // Clamp altitude to sensible range
        let clampedAltitude = min(max(paddedDistance, 1250), 350000)
        return MapCamera(
            centerCoordinate: adjustedCenter,
            distance: clampedAltitude,
            heading: 0,
            pitch: 0
        )
    }
}
