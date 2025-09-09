import Foundation
import CoreLocation
import _MapKit_SwiftUI

struct CameraUtility {
    static func cameraToFitPath(
        _ path: [CLLocationCoordinate2D],
        offset: CGFloat = 0.1,
        defaultLocation: CLLocationCoordinate2D? = nil
    ) -> MapCamera? {
        guard !path.isEmpty else {
            return nil
        }
        
        var invalidIndices: [Int] = []
        for (idx, p) in path.enumerated() {
            let latOK = p.latitude.isFinite && p.latitude >= -90.0 && p.latitude <= 90.0
            let lonOK = p.longitude.isFinite && p.longitude >= -180.0 && p.longitude <= 180.0
            if !(latOK && lonOK) {
                invalidIndices.append(idx)
            }
        }
        if !invalidIndices.isEmpty { return nil }
        
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

        let metersPerDegree = 111_000.0
        let boundingDistance = maxPaddedDelta * metersPerDegree
        let paddedDistance = boundingDistance

        let clampedAltitude = min(max(paddedDistance, 1250), 350000)
        
        Log("Camera Center: LAT \(adjustedCenter.latitude) LON \(adjustedCenter.longitude)")
        return MapCamera(
            centerCoordinate: adjustedCenter,
            distance: clampedAltitude,
            heading: 0,
            pitch: 0
        )
    }
}
