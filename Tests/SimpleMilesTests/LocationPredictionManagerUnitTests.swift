import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("LocationPredictionManager Unit Tests")
struct LocationPredictionManagerUnitTests {
    
    @MainActor
    @Test("Prediction update with fresh raw location")
    func testRawUpdate() {
        let manager = LocationPredictionManager.shared
        manager.reset()
        
        let loc = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: Date(), speed: 0, course: 0)
        manager.lastRawLocation = loc
        manager.lastRawHeading = 0
        manager.userMovementMode = .idle
        
        manager.updatePredictionState()
        
        #expect(manager.activeLocation?.latitude == 37)
    }

    @MainActor
    @Test("Step prediction branches")
    func testStepBranches() {
        let manager = LocationPredictionManager.shared
        manager.reset()
        
        // 1. Missing raw inputs
        manager.stepPrediction()
        #expect(manager.activeLocation == nil)
        
        // 2. High speed prediction
        let loc = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 90)
        manager.lastRawLocation = loc
        manager.lastRawHeading = 90
        
        manager.stepPrediction()
        #expect(manager.activeLocation != nil)
        #expect(abs(manager.activeLocation!.latitude) < 0.0001)
        #expect(manager.activeLocation!.longitude > 0)
        
        // 3. Low speed branch
        manager.reset()
        let locLow = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0.5, course: 90)
        manager.lastRawLocation = locLow
        manager.lastRawHeading = 90
        manager.stepPrediction()
        #expect(manager.activeLocation?.longitude == 0)
    }

    @MainActor
    @Test("Timer startup branches")
    func testTimer() async throws {
        let manager = LocationPredictionManager.shared
        manager.reset()
        
        manager.userMovementMode = .driving
        manager.updatePredictionState()
        #expect(manager.userMovementMode == .driving)
        
        manager.userMovementMode = .idle
        manager.updatePredictionState()
        #expect(manager.userMovementMode == .idle)
    }

    @MainActor
    @Test("Coordinate projection math")
    func testMath() {
        let base = CLLocationCoordinate2D(latitude: 45, longitude: 45)
        let moved = base.coordinate(at: 10000, bearing: 0) // North 10km
        #expect(moved.latitude > 45)
        #expect(abs(moved.longitude - 45) < 0.001)
    }
}
