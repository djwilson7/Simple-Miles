import MapKit
import CoreLocation

enum MapOrientationMode {
    case northUp
    case headingUp
    case userDefinedRotation
    case free
}

final class MapCameraController {
    private(set) var orientationMode: MapOrientationMode = .northUp
    private var userDefinedCameraHeading: CLLocationDirection = 0

    func setOrientationMode(_ mode: MapOrientationMode) {
        self.orientationMode = mode
    }

    func updateUserDefinedCameraHeading(_ heading: CLLocationDirection) {
        self.userDefinedCameraHeading = heading
    }

    var currentCameraHeading: CLLocationDirection {
        switch orientationMode {
        case .northUp:
            return 0
        case .headingUp:
            return 0
        case .free:
            return 0
        case .userDefinedRotation:
            return userDefinedCameraHeading
        }
    }

    func makeCamera(
        coordinate: CLLocationCoordinate2D,
        currentHeading: CLLocationDirection,
        travelHeading: CLLocationDirection,
        speed: CLLocationSpeed,
        distance: CLLocationDistance
    ) -> MKMapCamera {
        let heading: CLLocationDirection

        switch orientationMode {
        case .northUp:
            heading = 0
        case .headingUp:
            heading = (speed >= 2.0) ? travelHeading : currentHeading
        case .free:
            heading = currentHeading
        case .userDefinedRotation:
            heading = userDefinedCameraHeading
        }

        let camera = MKMapCamera()
        camera.centerCoordinate = coordinate
        camera.heading = heading
        camera.pitch = 0
        camera.altitude = distance
        return camera
    }

    private func shortestRotation(from: CLLocationDirection, to: CLLocationDirection) -> CLLocationDirection {
        let delta = fmod(to - from + 540, 360) - 180
        return from + delta
    }
}
