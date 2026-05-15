import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation
import MapKit

@Suite("CameraModel Tests")
struct CameraModelTests {
    
    @Test("Initialization and properties")
    func testCameraModel() {
        let center = CLLocationCoordinate2D(latitude: 37, longitude: -122)
        let model = CameraModel(center: center, altitude: 1000, heading: 90, pitch: 45)
        
        #expect(model.center.latitude == 37)
        #expect(model.altitude == 1000)
        #expect(model.heading == 90)
        #expect(model.pitch == 45)
    }
    
    @Test("Fitted camera calculation")
    func testFittedCamera() {
        let path = [
            CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
            CLLocationCoordinate2D(latitude: 37.4317, longitude: -122.1325)
        ]
        
        let fitted = CameraModel.forPath(path, pitch: 0)
        #expect(fitted != nil)
        #expect(fitted!.altitude >= 1250)
        
        // Test nil branch
        #expect(CameraModel.forPath([]) == nil)
    }
}
