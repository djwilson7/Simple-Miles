import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("TripMeta Tests")
struct TripMetaTests {
    
    @Test("Computed properties")
    func testComputed() {
        let meta = TripMeta(
            id: "test", type: 1, startTs: 1000, endTs: 2000,
            distanceM: 100, durationS: 50,
            bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0,
            sizeBytes: 0, version: 1
        )
        #expect(meta.startDate.timeIntervalSince1970 == 1.0)
        #expect(meta.endDate.timeIntervalSince1970 == 2.0)
        #expect(meta.tripType == .business)
        #expect(!meta.isEmpty)
        
        let empty = TripMeta(id: "e", type: 0, startTs: 0, endTs: 0, distanceM: 0, durationS: 0, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        #expect(empty.isEmpty)
    }
}
