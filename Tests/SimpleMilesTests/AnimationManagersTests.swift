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
    @Test("LocationAnimationManager spline tail")
    func testLocationAnimation() {
        let manager = LocationAnimationManager()
        let gt = [CLLocationCoordinate2D(latitude: 0, longitude: 0), CLLocationCoordinate2D(latitude: 0.1, longitude: 0.1)]
        let puck = CLLocationCoordinate2D(latitude: 0.2, longitude: 0.2)
        
        let tail = manager.generateSplineTail(groundTruth: gt, puck: puck)
        
        #expect(!tail.isEmpty)
        #expect(tail.first?.latitude == 0.0)
        #expect(tail.last?.latitude == 0.2)
    }
}
