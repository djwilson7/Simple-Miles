import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("CameraManager Tests")
struct CameraManagerTests {
    
    @MainActor
    @Test("Orientation modes")
    func testOrientation() {
        let manager = CameraManager.shared
        manager.updateOrientationMode(.northUp) // Set initial known state
        
        manager.updateOrientationMode(.headingUp)
        #expect(manager.orientationMode == .headingUp)
        #expect(manager.lastNonFreeRoamOrientation == .northUp)
        
        manager.updateOrientationMode(.freeRoam)
        #expect(manager.orientationMode == .freeRoam)
        
        manager.resetOrientation()
        #expect(manager.orientationMode == .headingUp)
    }

    @MainActor
    @Test("Review mode and fallback")
    func testReview() {
        let manager = CameraManager.shared
        manager.reset()
        
        // Empty path should trigger fallback (which does nothing if lastLocation is nil)
        manager.setCameraToReview(path: [])
        #expect(manager.desiredCameraPosition == nil)
        
        // Valid path
        let path = [CLLocationCoordinate2D(latitude: 37, longitude: -122)]
        manager.setCameraToReview(path: path)
        #expect(manager.desiredCameraPosition != nil)
    }
    
    @MainActor
    @Test("Orientation update branches")
    func testOrientationBranches() {
        let manager = CameraManager.shared
        manager.orientationMode = .northUp
        
        manager.updateOrientationMode(.freeRoam)
        #expect(manager.lastNonFreeRoamOrientation == .northUp)
        
        manager.updateOrientationMode(.headingUp)
        #expect(manager.orientationMode == .headingUp)
    }

    @MainActor
    @Test("Altitude persistence")
    func testAltitude() {
        let manager = CameraManager.shared
        manager.saveUserCameraDistance(3000)
        #expect(manager.loadSavedCameraDistance() == 3000)
        
        manager.saveUserCameraDistance(nil)
        #expect(manager.loadSavedCameraDistance() == nil)
    }

    @MainActor
    @Test("Save and load invalid altitude")
    func testInvalidAltitude() {
        let manager = CameraManager.shared
        manager.saveUserCameraDistance(-100)
        #expect(manager.loadSavedCameraDistance() == nil)
        manager.saveUserCameraDistance(0)
        #expect(manager.loadSavedCameraDistance() == nil)
    }
    
    @MainActor
    @Test("Set Camera to free roam with heading")
    func testSetCameraFreeRoam() {
        let manager = CameraManager.shared
        manager.setCameraToFreeRoam(heading: 180)
        #expect(manager.mapHeading == 180)
    }

    @MainActor
    @Test("Review mode fallback to last location")
    func testReviewFallback() {
        let manager = CameraManager.shared
        manager.reset()
        // Simulate last location
        let lastLoc = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 10, longitude: 10), timestamp: Date(), speed: 10, course: 0)
        manager.handleCameraUpdate(location: lastLoc, heading: 0, orientation: .northUp)
        
        manager.setCameraToReview(path: [])
        #expect(manager.desiredCameraPosition?.centerCoordinate.latitude == 10)
    }

    @MainActor
    @Test("Handle Camera Update all orientations")
    func testHandleCameraUpdateOrientations() {
        let manager = CameraManager.shared
        let loc = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 20, longitude: 20), timestamp: Date(), speed: 10, course: 0)
        
        manager.handleCameraUpdate(location: loc, heading: 45, orientation: .headingUp)
        #expect(manager.desiredCameraPosition?.heading == 45)
        
        let previous = manager.desiredCameraPosition
        manager.handleCameraUpdate(location: loc, heading: 45, orientation: .freeRoam)
        #expect(manager.desiredCameraPosition == previous) // unchanged
        
        manager.handleCameraUpdate(location: loc, heading: 45, orientation: .reviewing)
        #expect(manager.desiredCameraPosition == previous) // unchanged
    }
}
