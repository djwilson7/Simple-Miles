import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("DrivingStateManager Unit Tests")
struct DrivingStateManagerUnitTests {
    
    @MainActor
    @Test("Update with low speed and short distance")
    func testLowSpeed() {
        let manager = DrivingStateManager.shared
        manager.reset()
        
        let p1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0, course: 0)
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0.00001, longitude: 0.00001), timestamp: Date(), speed: 1, course: 0)
        
        manager.evaluateMotion(current: p1)
        manager.evaluateMotion(current: p2)
        
        #expect(manager.state == false)
    }
    
    @MainActor
    @Test("Update with high speed")
    func testHighSpeed() {
        let manager = DrivingStateManager.shared
        manager.reset()
        
        let p1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0, course: 0)
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0.0005, longitude: 0.0005), timestamp: Date(), speed: 10, course: 0)
        
        manager.evaluateMotion(current: p1)
        manager.evaluateMotion(current: p2)
        
        #expect(manager.state == true)
    }
}
