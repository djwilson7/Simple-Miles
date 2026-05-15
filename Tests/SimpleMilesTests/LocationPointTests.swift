import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("LocationPoint Tests")
struct LocationPointTests {
    
    @Test("Initialization from CLLocation")
    func testCLLocationInit() {
        let clLoc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122),
            altitude: 10,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 90,
            speed: 10,
            timestamp: Date()
        )
        let point = LocationPoint(clLoc)
        #expect(point.latitude == 37)
        #expect(point.longitude == -122)
        #expect(point.speed == 10)
        #expect(point.course == 90)
    }
    
    @Test("Equatable and Hashable")
    func testEquatability() {
        let p1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0, course: 0)
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date().addingTimeInterval(100), speed: 10, course: 10)
        let p3 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 0, course: 0)
        
        #expect(p1 == p2) // Defined by coordinates only
        #expect(p1 != p3)
        #expect(p1.hashValue == p2.hashValue)
    }
    
    @Test("Distance calculation")
    func testDistance() {
        let p1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0, course: 0)
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 0, course: 0)
        #expect(p1.distance(to: p2) > 0)
        #expect(p1.distance(to: p1) == 0)
    }
    
    @Test("Negative speed clamping")
    func testClamping() {
        let clLoc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, speed: -10, timestamp: Date()
        )
        let p = LocationPoint(clLoc)
        #expect(p.speed == 0)
        
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: -5, course: 0)
        #expect(p2.speed == 0)
    }
    
    @Test("Hash consistency")
    func testHash() {
        let p1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: Date(), speed: 0, course: 0)
        let p2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: Date().addingTimeInterval(100), speed: 10, course: 10)
        
        var hasher1 = Hasher()
        p1.hash(into: &hasher1)
        
        var hasher2 = Hasher()
        p2.hash(into: &hasher2)
        
        #expect(hasher1.finalize() == hasher2.finalize())
    }
    
    @Test("Initializer validation")
    func testValidation() {
        let p = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 0, course: 0)
        #expect(p.latitude == 0)
    }
    
    @Test("Codable implementation")
    func testCodable() throws {
        let p = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37.5, longitude: -122.5), timestamp: Date(), speed: 10, course: 90)
        let data = try JSONEncoder().encode(p)
        let decoded = try JSONDecoder().decode(LocationPoint.self, from: data)
        #expect(decoded == p)
        #expect(decoded.speed == p.speed)
    }
}
