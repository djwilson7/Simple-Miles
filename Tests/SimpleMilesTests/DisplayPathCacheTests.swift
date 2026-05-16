import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("DisplayPathCache Tests", .serialized)
struct DisplayPathCacheTests {
    
    @Test("LRU Cache behavior")
    func testLRU() {
        let cache = DisplayPathCache(capacity: 10)
        let coords = [CLLocationCoordinate2D(latitude: 0, longitude: 0)]
        
        // Fill cache
        for i in 1...10 {
            cache.set("key-\(i)", value: coords)
        }
        
        #expect(cache.get("key-1") != nil)
        
        // Add one more, key-2 should be evicted (since key-1 was accessed)
        cache.set("key-11", value: coords)
        
        #expect(cache.get("key-2") == nil)
        #expect(cache.get("key-1") != nil)
        #expect(cache.get("key-11") != nil)
    }
    
    @Test("Remove all")
    func testRemoveAll() {
        let cache = DisplayPathCache(capacity: 10)
        cache.set("a", value: [])
        cache.removeAll()
        #expect(cache.get("a") == nil)
    }

    @Test("Cache remove specific key")
    func testRemove() {
        let cache = DisplayPathCache(capacity: 10)
        cache.set("a", value: [])
        cache.remove("a")
        #expect(cache.get("a") == nil)
        
        // Remove non-existent key shouldn't crash
        cache.remove("b")
    }

    @Test("Cache update existing key")
    func testUpdateExisting() {
        let cache = DisplayPathCache(capacity: 10)
        let coords1 = [CLLocationCoordinate2D(latitude: 0, longitude: 0)]
        let coords2 = [CLLocationCoordinate2D(latitude: 1, longitude: 1)]
        
        cache.set("a", value: coords1)
        cache.set("a", value: coords2)
        
        let retrieved = cache.get("a")
        #expect(retrieved?.first?.latitude == 1)
    }

    @Test("Cache init with small capacity")
    func testSmallCapacity() {
        let cache = DisplayPathCache(capacity: 2) // Will be clamped to max(8, 2) = 8
        // Let's add 9 items
        for i in 1...9 {
            cache.set("key-\(i)", value: [])
        }
        #expect(cache.get("key-1") == nil) // 1 was evicted
        #expect(cache.get("key-2") != nil)
    }
}
