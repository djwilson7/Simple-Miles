import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation
import MapKit
import SwiftUI

@Suite("CameraAnimationManager Unit Tests")
struct CameraAnimationManagerUnitTests {
    
    @MainActor
    @Test("Ease in out cosine")
    func testEasing() {
        #expect(CameraAnimationManager.easeInOutCosine(0) == 0)
        #expect(CameraAnimationManager.easeInOutCosine(1) == 1)
        #expect(abs(CameraAnimationManager.easeInOutCosine(0.5) - 0.5) < 0.0001)
    }
    
    @MainActor
    @Test("Shortest heading delta")
    func testHeadingDelta() {
        #expect(CameraAnimationManager.shortestHeadingDelta(from: 350, to: 10) == 20)
        #expect(CameraAnimationManager.shortestHeadingDelta(from: 10, to: 350) == -20)
    }
    
    @MainActor
    @Test("Interpolate cameras")
    func testInterpolate() {
        let start = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), distance: 1000, heading: 0, pitch: 0)
        let end = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), distance: 2000, heading: 90, pitch: 45)
        
        let mid = CameraAnimationManager.interpolate(from: start, to: end, t: 0.5)
        #expect(mid.centerCoordinate.latitude == 0.5)
        #expect(mid.distance == 1500)
        #expect(mid.heading == 45)
    }
    
    @MainActor
    @Test("Manual timer tick")
    func testManualTick() {
        let manager = CameraAnimationManager()
        let start = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), distance: 1000, heading: 0, pitch: 0)
        let end = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), distance: 1000, heading: 0, pitch: 0)
        
        var updated = false
        manager.animate(from: start, to: end, isReviewing: false, onUpdate: { _ in
            updated = true
        })
        
        // Mock start time to be in the past
        manager.cameraAnimationStartTime = Date().addingTimeInterval(-1.0)
        
        manager.handleTimerTick(Timer())
        
        #expect(updated)
        #expect(manager.cameraAnimationTimer == nil) // Should have completed
    }

    @MainActor
    @Test("Mid-flight animation retargeting")
    func testMidFlightRetargeting() {
        let manager = CameraAnimationManager()
        let start = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), distance: 1000, heading: 0, pitch: 0)
        let end1 = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), distance: 1000, heading: 0, pitch: 0)
        let end2 = MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2), distance: 1000, heading: 0, pitch: 0)

        manager.animate(from: start, to: end1, isReviewing: true, onUpdate: { _ in })
        
        // Mock progress
        manager.cameraAnimationStartTime = Date().addingTimeInterval(-0.4)
        manager.cameraAnimationDuration = 0.8
        
        manager.animate(from: start, to: end2, isReviewing: false, onUpdate: { _ in })
        
        #expect(manager.animationStartCamera?.centerCoordinate.latitude != 0)
        #expect(manager.cameraAnimationDuration == 0.95)
    }

    @MainActor
    @Test("Handle timer tick with nil properties")
    func testTimerTickNilProperties() {
        let manager = CameraAnimationManager()
        manager.cameraAnimationTimer = Timer()
        manager.handleTimerTick(Timer())
        #expect(manager.cameraAnimationTimer == nil)
    }
}
