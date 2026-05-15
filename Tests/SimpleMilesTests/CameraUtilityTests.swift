import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation
import MapKit

@Suite("CameraUtility Tests")
struct CameraUtilityTests {
    
    @Test("Camera to fit path")
    func testFitPath() {
        let path = [
            CLLocationCoordinate2D(latitude: 37.3317, longitude: -122.0325),
            CLLocationCoordinate2D(latitude: 37.4317, longitude: -122.1325)
        ]
        
        let camera = CameraUtility.cameraToFitPath(path)
        #expect(camera != nil)
        #expect(camera?.distance ?? 0 >= 1250)
    }
    
    @Test("Fit empty path")
    func testEmptyPath() {
        let camera = CameraUtility.cameraToFitPath([])
        #expect(camera == nil)
    }
    
    @Test("Fit path with invalid coordinates")
    func testInvalidPath() {
        let path = [
            CLLocationCoordinate2D(latitude: 100, longitude: 200)
        ]
        let camera = CameraUtility.cameraToFitPath(path)
        #expect(camera == nil)
    }
}
