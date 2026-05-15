import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("Geometry Helpers Tests")
struct GeometryTests {
    
    @Test("Coordinate projection")
    func testProjection() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let projected = start.coordinate(at: 111000, bearing: 0) // ~1 degree north
        #expect(abs(projected.latitude - 1.0) < 0.1)
        #expect(abs(projected.longitude - 0.0) < 0.1)
    }
}
