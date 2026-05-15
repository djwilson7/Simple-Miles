import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation
import MapKit

@Suite("CameraManager Unit Tests")
struct CameraManagerUnitTests {
    
    @MainActor
    @Test("Input binding")
    func testBinding() async throws {
        let manager = CameraManager.shared
        manager.reset()
        
        let predictor = LocationPredictionManager.shared
        predictor.reset()
        
        let loc = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: Date(), speed: 10, course: 90)
        predictor.lastRawLocation = loc
        predictor.lastRawHeading = 90
        predictor.userMovementMode = .idle
        predictor.updatePredictionState()
        
        // Wait for Combine
        for _ in 1...10 {
            if manager.desiredCameraPosition != nil { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        #expect(manager.desiredCameraPosition != nil)
    }
}
