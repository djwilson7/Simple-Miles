import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("PathEncoder Deep Tests")
struct PathEncoderDeepTests {
    
    @Test("Various deltas")
    func testVariousDeltas() throws {
        let coords = [
            CLLocationCoordinate2D(latitude: 0, longitude: 0),
            CLLocationCoordinate2D(latitude: 0.0001, longitude: 0.0001), // Small
            CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0), // Medium
            CLLocationCoordinate2D(latitude: 45.0, longitude: 90.0) // Large
        ]
        let encoded = try PathEncoder.encodeDisplay(coords: coords)
        let decoded = try PathDecoder.decodeDisplay(encoded, codec: "lzfse", version: 1)
        #expect(decoded.count == 4)
    }
}
