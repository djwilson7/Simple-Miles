import Foundation
import MapKit
// --- Camera Model Example ---

// Base model for representing a camera state
struct CameraModel {
    var center: CLLocationCoordinate2D
    var altitude: CLLocationDistance
    var heading: CLLocationDirection
    var pitch: CGFloat
}

// Model for storing a camera with an associated path (e.g., for review mode)
struct PathCameraModel {
    var camera: CameraModel
    var path: [CLLocationCoordinate2D]
}

// Extension example: create a CameraModel that fits a path
extension CameraModel {
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
