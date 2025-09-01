import Foundation
import MapKit

enum CameraOrientationMode {
    case northUp
    case headingUp
    case freeRoam
    case reviewing
}

struct CameraModel {
    var center: CLLocationCoordinate2D
    var altitude: CLLocationDistance
    var heading: CLLocationDirection
    var pitch: CGFloat
}

struct PathCameraModel {
    var camera: CameraModel
    var path: [CLLocationCoordinate2D]
}

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
