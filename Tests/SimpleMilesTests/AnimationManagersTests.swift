import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation
import MapKit
import SwiftUI

@Suite("Animation Managers Tests")
struct AnimationManagersTests {

    @MainActor
    @Test("CameraAnimationManager basic instantiation")
    func testCameraAnimation() {
        _ = CameraAnimationManager()
    }
    
    @MainActor
    @Test("LocationAnimationManager interpolation")
    func testLocationAnimation() {
        let manager = LocationAnimationManager()
        let start = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 0)
        let end = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 10, course: 0)
        
        manager.updateAnchors(live: start, staticLast: nil)
        
        var lastPoint: LocationPoint?
        manager.animate(from: start, to: end, travelStateIsTraveling: false) { point, _ in
            lastPoint = point
        }
        
        #expect(lastPoint?.latitude == 1.0)
    }
}
