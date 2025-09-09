import Foundation
import MapKit

/// Represents a camera configuration for the map view.
/// - Units:
///   - altitude: meters
///   - heading: degrees
///   - pitch: degrees
struct CameraModel {
    // MARK: - Stored Properties
    var center: CLLocationCoordinate2D
    var altitude: CLLocationDistance
    var heading: CLLocationDirection
    var pitch: CGFloat
}

// MARK: - Supporting Types
/// Groups a camera with a path it is intended to display.
struct PathCameraModel {
    var camera: CameraModel
    var path: [CLLocationCoordinate2D]
}

/// Orientation modes for controlling the map camera.
enum CameraOrientationMode {
    case northUp
    case headingUp
    case freeRoam
    case reviewing
}

// MARK: - Mapping Helpers
extension CameraModel {
    /// Produces a CameraModel that fits the given path using CameraUtility.
    /// - Parameters:
    ///   - path: The path to fit.
    ///   - pitch: Optional pitch to apply to the resulting camera (degrees).
    /// - Returns: A CameraModel if the path is valid; otherwise nil.
    static func forPath(_ path: [CLLocationCoordinate2D], pitch: CGFloat = 0) -> CameraModel? {
        if let fittedCamera = CameraUtility.cameraToFitPath(path) {
            return CameraModel(
                center: fittedCamera.centerCoordinate,
                altitude: fittedCamera.distance,
                heading: fittedCamera.heading,
                pitch: pitch
            )
        } else {
            return nil
        }
    }
}
