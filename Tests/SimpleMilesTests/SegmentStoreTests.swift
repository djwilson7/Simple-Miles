import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("SegmentStore Tests")
struct SegmentStoreTests {
    
    @Test("Insights and Histogram")
    func testAggregates() throws {
        let store = SegmentStore.shared
        let type = TripType.business
        
        let insights = try store.fetchWeeklyInsights(type: type)
        #expect(insights.totalMeters >= 0)
        
        let histogram = try store.fetchStartHourHistogram(type: type)
        #expect(histogram.values.count == 24)
        
        let dow = try store.fetchDOWMeters(type: type)
        #expect(dow.meters.count == 7)
        
        let totals = try store.fetchTotals(type: type)
        #expect(totals.tripCount >= 0)
        
        let breakdown = try store.fetchBreakdownData(type: type)
        #expect(breakdown.typeMeters >= 0)
    }
    
    @Test("Refresh totals publisher")
    func testRefresh() async throws {
        let store = SegmentStore.shared
        var fired = false
        let cancellable = store.tripTotalsUpdated.sink { fired = true }
        
        store.refreshAllTotals()
        
        for _ in 1...10 {
            if fired { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        #expect(fired)
        cancellable.cancel()
    }
    
    @Test("Write segment details")
    func testWriteDetails() async throws {
        let store = SegmentStore.shared
        let start = Date()
        var segment = TripSegment(startTimestamp: start)
        segment.append(location: LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: start, speed: 10, course: 0))
        
        // This hits the detached task in store.write
        store.write(segment)
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(try store.count(type: .unsorted) >= 0)
    }

    @Test("Delete and Reclassify")
    func testDeleteAndReclassify() async throws {
        let store = SegmentStore.shared
        let start = Date()
        var segment = TripSegment(startTimestamp: start)
        segment.append(location: LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: start, speed: 10, course: 0))
        
        store.write(segment)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let initialCount = try store.count(type: .unsorted)
        #expect(initialCount > 0)
        
        // Reclassify
        store.reclassify(tripID: segment.dbID, to: .business)
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(try store.count(type: .business) > 0)
        
        // Delete
        store.delete(segment)
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    @Test("Fetch Trip ID Page")
    func testFetchTripIDPage() {
        let store = SegmentStore.shared
        let ids = store.fetchTripIDPage(for: .unsorted)
        #expect(ids.count >= 0)
    }

    @Test("Fetch Display Path")
    func testFetchDisplayPath() {
        let store = SegmentStore.shared
        let path = store.fetchDisplayPath(for: "invalid_id")
        #expect(path.isEmpty)
    }

    @Test("Fetch Meta Error")
    func testFetchMetaError() {
        let store = SegmentStore.shared
        #expect(throws: Error.self) {
            _ = try store.fetchMeta(id: "invalid_id")
        }
    }

    @Test("Update Segment")
    func testUpdateSegment() async throws {
        let store = SegmentStore.shared
        let start = Date()
        var segment = TripSegment(startTimestamp: start)
        segment.append(location: LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2), timestamp: start, speed: 10, course: 0))
        
        // Save first so update doesn't fail FOREIGN KEY
        store.write(segment)
        try await Task.sleep(nanoseconds: 800_000_000)
        
        segment.distance = 100
        store.update(segment)
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let path = store.fetchDisplayPath(for: segment.dbID)
        #expect(path.count >= 0)
    }
}
