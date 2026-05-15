import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("TripSegmentModel Tests")
struct TripSegmentModelTests {
    
    @Test("Finalize segment")
    func testFinalize() {
        let start = Date()
        var segment = TripSegment(startTimestamp: start)
        let end = start.addingTimeInterval(100)
        segment.finalize(at: end)
        
        #expect(segment.endTimestamp == end)
        #expect(segment.duration == 100)
    }
    
    @Test("Append segment")
    func testAppendSegment() {
        var s1 = TripSegment(startTimestamp: Date())
        s1.distance = 10
        s1.duration = 10
        
        var s2 = TripSegment(startTimestamp: Date())
        s2.distance = 20
        s2.duration = 20
        
        s1.merge(with: s2)
        #expect(s1.distance == 30)
        #expect(s1.duration == 30)
    }
}
