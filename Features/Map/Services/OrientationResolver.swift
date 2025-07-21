////
////  OrientationResolver.swift
////  SimpleMiles
////
////  Created by Invictus Maneo on 7/21/25.
////
//
//
//import MapKit
//import CoreLocation
//
//struct OrientationResolver {
//    static func resolve(
//        userHeading: CLLocationDirection,
//        travelHeading: CLLocationDirection,
//        coordinate: CLLocationCoordinate2D,
//        speed: CLLocationSpeed,
//        distance: CLLocationDistance,
//        cameraController: MapCameraController
//    ) -> (camera: MKMapCamera, arrowRotation: CLLocationDirection) {
//        let camera = cameraController.makeCamera(
//            coordinate: coordinate,
//            currentHeading: userHeading,
//            travelHeading: travelHeading,
//            speed: speed,
//            distance: distance
//        )
//
//        let arrowRotation = normalizedAngle(userHeading - camera.heading)
//
//        return (camera, arrowRotation)
//    }
//
//    private static func normalizedAngle(_ angle: CLLocationDirection) -> CLLocationDirection {
//        let adjusted = fmod(angle + 360, 360)
//        return adjusted < 0 ? adjusted + 360 : adjusted
//    }
//}
