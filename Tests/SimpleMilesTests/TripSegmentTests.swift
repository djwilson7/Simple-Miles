import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("TripSegment Tests")
struct TripSegmentTests {
    
    @Test("Initialization and appending locations")
    func testSegment() {
        let start = Date()
        var segment = TripSegment(startTimestamp: start)
        #expect(segment.startTimestamp == start)
        #expect(segment.pathCoordinates.isEmpty)
        #expect(segment.distance == 0)
        
        let loc1 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: start, speed: 10, course: 0)
        let loc2 = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0.1, longitude: 0), timestamp: start.addingTimeInterval(10), speed: 10, course: 0)
        
        segment.append(location: loc1)
        #expect(segment.pathCoordinates.count == 1)
        
        segment.append(location: loc2)
        #expect(segment.pathCoordinates.count == 2)
        #expect(segment.distance > 0)
    }
    
    @Test("Merging segments")
    func testMerge() {
        var s1 = TripSegment(startTimestamp: Date(timeIntervalSince1970: 1000))
        s1.append(location: LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(timeIntervalSince1970: 1000), speed: 10, course: 0))
        s1.distance = 100
        s1.duration = 50
        
        var s2 = TripSegment(startTimestamp: Date(timeIntervalSince1970: 2000))
        s2.append(location: LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(timeIntervalSince1970: 2000), speed: 10, course: 0))
        s2.distance = 200
        s2.duration = 100
        
        s1.merge(with: s2)
        
        #expect(s1.distance == 300)
        #expect(s1.duration == 150)
        #expect(s1.pathCoordinates.count == 2)
    }
}
