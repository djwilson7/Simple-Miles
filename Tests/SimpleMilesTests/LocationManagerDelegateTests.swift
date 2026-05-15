import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("LocationManager Delegate Tests")
struct LocationManagerDelegateTests {
    
    @MainActor
    @Test("Seed last known details")
    func testSeed() {
        let manager = LocationManager.shared
        let point = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: Date(), speed: 0, course: 0)
        manager.persistLastKnownLocation(point)
        
        manager.seedLastKnownIfAvailable()
        #expect(manager.currentLocation?.latitude == 37)
    }
    
    @MainActor
    @Test("Authorization states details")
    func testDetailedAuth() {
        let manager = LocationManager.shared
        // We'll just hit the branches via delegate calls
        manager.locationManagerDidChangeAuthorization(CLLocationManager())
    }

    @MainActor
    @Test("Continuous updates")
    func testContinuous() {
        let manager = LocationManager.shared
        manager.startContinuousUpdates()
    }
    
    @MainActor
    @Test("App activation details")
    func testActivationDetails() {
        _ = LocationManager.shared
        // Set state to not suppressing
        NotificationCenter.default.post(name: NSNotification.Name("UIApplicationDidBecomeActiveNotification"), object: nil)
        
        // Call again
        NotificationCenter.default.post(name: NSNotification.Name("UIApplicationDidBecomeActiveNotification"), object: nil)
    }
}
