// CameraUtility.swift
// A utility for camera fitting/path calculations shared by CameraManager and MapViewModel

import Foundation
import CoreLocation
import _MapKit_SwiftUI

struct CameraUtility {
    /// Returns a MapCamera that fits the given path with a specified vertical offset.
    static func cameraToFitPath(
        _ coordinates: [CLLocationCoordinate2D],
        offset: CGFloat = 0.4,
        defaultLocation: CLLocationCoordinate2D? = nil
    ) -> MapCamera {
        guard !coordinates.isEmpty else {
            let fallback = defaultLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            return MapCamera(centerCoordinate: fallback, distance: 1500, heading: 0, pitch: 0)
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coord in coordinates {
            minLat = min(minLat, coord.latitude)
            maxLat = max(maxLat, coord.latitude)
            minLon = min(minLon, coord.longitude)
            maxLon = max(maxLon, coord.longitude)
        }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        let verticalAnchorRatio = 0.3
        let shiftRatio = 0.7 - verticalAnchorRatio
        let latSpan = maxLat - minLat
        let verticalShiftDegrees = latSpan * shiftRatio

        let adjustedCenter = CLLocationCoordinate2D(
            latitude: centerLat - verticalShiftDegrees,
            longitude: centerLon
        )

        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon
        let horizontalPaddingFactor = 5.0
        let verticalPaddingFactor = 5.0 + Double(offset)
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
