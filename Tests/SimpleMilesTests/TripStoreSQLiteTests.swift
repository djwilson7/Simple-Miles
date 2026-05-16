import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("TripStoreSQLite Tests", .serialized)
struct TripStoreSQLiteTests {
    
    let store: TripStoreSQLite
    
    init() {
        let codecs = TripStoreSQLite.Codecs(
            encodeDisplay: { try PathEncoder.encodeDisplay(coords: $0) },
            decodeDisplay: { try PathDecoder.decodeDisplay($0, codec: $1, version: $2) }
        )
        self.store = TripStoreSQLite(codecs: codecs)
    }
    
    @Test("Save and fetch trip")
    func testSaveFetch() throws {
        let id = "store-test-1"
        let start = Date()
        let end = start.addingTimeInterval(3600)
        let points = [
            LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: start, speed: 10, course: 0),
            LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37.1, longitude: -122.1), timestamp: end, speed: 10, course: 0)
        ]
        
        try store.save(
            id: id,
            type: .business,
            start: start,
            end: end,
            distanceMeters: 5000,
            durationSeconds: 3600,
            rawPoints: points
        )
        
        let meta = try store.fetchMeta(id: id)
        #expect(meta.id == id)
        #expect(meta.distanceM == 5000)
        
        let path = try store.fetchDisplayPath(id: id)
        #expect(path.count == 2)
        
        try store.delete(id: id)
    }
    
    @Test("Update trip")
    func testUpdate() throws {
        let id = "store-test-update"
        let start = Date()
        try store.save(id: id, type: .personal, start: start, end: start, distanceMeters: 0, durationSeconds: 0, rawPoints: [])
        
        try store.update(id: id, type: .personal, start: start, end: start.addingTimeInterval(100), distanceMeters: 100, durationSeconds: 100, rawPoints: [])
        
        let meta = try store.fetchMeta(id: id)
        #expect(meta.distanceM == 100)
        
        try store.reclassify(id: id, to: .business)
        let meta2 = try store.fetchMeta(id: id)
        #expect(meta2.type == 1)
        
        let totals = try store.fetchTotals(type: .business)
        #expect(totals.tripCount >= 1)
        
        try store.delete(id: id)
    }
}
