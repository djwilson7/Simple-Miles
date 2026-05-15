import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("DrivingStateManager Deep Tests")
struct DrivingStateDeepTests {
    
    @MainActor
    @Test("Stop detection")
    func testStop() async throws {
        let manager = DrivingStateManager.shared
        manager.reset()
        
        let p1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0, course: 0)
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0.0005, longitude: 0.0005), timestamp: Date().addingTimeInterval(1), speed: 10, course: 0)
        
        manager.evaluateMotion(current: p1)
        manager.evaluateMotion(current: p2)
        
        #expect(manager.state == true)
        
        // 2. Stop moving but with low speed
        let still = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0.00051, longitude: 0.00051), timestamp: Date().addingTimeInterval(2), speed: 0, course: 0)
        manager.evaluateMotion(current: still)
        
        // Simulate time passing
        manager.lastMovementTime = Date().addingTimeInterval(-20)
        
        // 3. Wait for evaluation timer (10s)
        // Manually trigger the handler
        manager.handleEvaluationTimer(Timer())
        
        #expect(manager.state == false)
        manager.reset()
    }
}
