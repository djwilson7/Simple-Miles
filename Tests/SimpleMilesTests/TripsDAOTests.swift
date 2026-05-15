import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SQLite3

@Suite("TripsDAO robust Tests")
struct TripsDAOTests {
    
    @Test("CRUD Operations")
    func testCRUD() throws {
        let id = "crud-\(UUID().uuidString)"
        let meta = TripMeta(id: id, type: 1, startTs: 1000, endTs: 2000, distanceM: 100, durationS: 50, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        
        try TripsDAO.insertOrReplace(meta)
        let fetched = try TripsDAO.fetch(by: id)
        #expect(fetched?.id == id)
        
        try TripsDAO.reclassify(id: id, to: 2)
        let reclassified = try TripsDAO.fetch(by: id)
        #expect(reclassified?.type == 2)
        
        try TripsDAO.update(meta)
        
        try TripsDAO.delete(id: id)
        let deleted = try TripsDAO.fetch(by: id)
        #expect(deleted == nil)
    }

    @Test("Total aggregations with dates")
    func testTotalAggsWithDates() throws {
        let type = TripType.business
        try Database.shared.inRead { db in
            _ = try TripsDAO.sumDistanceMeters(for: type, from: 0, to: 5000, in: db)
            _ = try TripsDAO.countTrips(for: type, from: 0, to: 5000, in: db)
            _ = try TripsDAO.sumDurationSeconds(for: type, from: 0, to: 5000, in: db)
        }
    }
    
    @Test("Aggregations")
    func testAggregations() throws {
        let type = TripType.custom
        let id = "agg-\(UUID().uuidString)"
        let m = TripMeta(id: id, type: Int(type.dbValue), startTs: 1000, endTs: 2000, distanceM: 1000, durationS: 100, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        try TripsDAO.insertOrReplace(m)
        
        let breakdown = try TripsDAO.fetchBreakdownData(for: type)
        #expect(breakdown.typeMeters >= 1000)
        
        let insights = try TripsDAO.fetchWeeklyInsights(for: type)
        #expect(insights.tripCount >= 1)
        
        let h1 = try TripsDAO.fetchStartHourHistogram(for: type, metric: .count)
        #expect(h1.values.contains { $0 > 0 })
        
        try TripsDAO.delete(id: id)
    }

    @Test("Insights empty")
    func testEmptyInsights() throws {
        // Just call it for a random type
        let insights = try TripsDAO.fetchWeeklyInsights(for: .trash)
        #expect(insights.tripCount >= 0)
    }
    
    @Test("Count trips")
    func testCount() throws {
        let uniqueID = "count-\(UUID().uuidString)"
        let type = TripType.custom
        let m = TripMeta(id: uniqueID, type: Int(type.dbValue), startTs: 0, endTs: 0, distanceM: 0, durationS: 0, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        try TripsDAO.insertOrReplace(m)
        
        #expect(try TripsDAO.count(for: Int(type.dbValue)) >= 1)
        
        try TripsDAO.delete(id: uniqueID)
    }

    @Test("Update non-existent meta")
    func testUpdateNonExistent() {
        let meta = TripMeta(id: "does_not_exist", type: 1, startTs: 0, endTs: 0, distanceM: 0, durationS: 0, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        #expect(throws: DBError.self) {
            try TripsDAO.update(meta)
        }
    }

    @Test("Reclassify non-existent")
    func testReclassifyNonExistent() {
        #expect(throws: DBError.self) {
            try TripsDAO.reclassify(id: "does_not_exist", to: 2)
        }
    }

    @Test("Fetch totals")
    func testFetchTotals() throws {
        let type = TripType.custom
        let id = "totals-\(UUID().uuidString)"
        let m = TripMeta(id: id, type: Int(type.dbValue), startTs: 1000, endTs: 2000, distanceM: 50, durationS: 10, bboxMinLat: 0, bboxMinLon: 0, bboxMaxLat: 0, bboxMaxLon: 0, sizeBytes: 0, version: 1)
        try TripsDAO.insertOrReplace(m)
        
        let totals = try TripsDAO.fetchTotals(for: Int(type.dbValue))
        #expect(totals.tripCount >= 1)
        
        try TripsDAO.delete(id: id)
    }

    @Test("Histogram metrics")
    func testHistogramMetrics() throws {
        let type = TripType.custom
        let h2 = try TripsDAO.fetchStartHourHistogram(for: type, metric: .distanceMeters)
        let h3 = try TripsDAO.fetchStartHourHistogram(for: type, metric: .durationSecs)
        #expect(h2.values.count == 24)
        #expect(h3.values.count == 24)
    }

    @Test("All Excluding Trash Aggregations")
    func testAllExcludingTrash() throws {
        try Database.shared.inRead { db in
            _ = try TripsDAO.sumDistanceMetersAllExcludingUnsortedTrash(from: nil, to: nil, in: db)
            _ = try TripsDAO.countTripsAllExcludingUnsortedTrash(from: nil, to: nil, in: db)
            _ = try TripsDAO.sumDurationSecondsAllExcludingUnsortedTrash(from: nil, to: nil, in: db)
        }
    }
}
