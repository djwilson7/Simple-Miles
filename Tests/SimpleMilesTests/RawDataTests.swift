import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("Raw Data Models Tests")
struct RawDataTests {
    
    @Test("RawDOWData zero fixture")
    func testDOWZero() {
        let zero = RawDOWData.zero
        #expect(zero.meters.count == 7)
        #expect(zero.meters.allSatisfy { $0 == 0 })
    }

    @Test("RawDOWData direct init")
    func testDOWInit() {
        let dow = RawDOWData(meters: [1, 2, 3, 4, 5, 6, 7])
        #expect(dow.meters[0] == 1)
        #expect(dow.meters[6] == 7)
    }
    
    @Test("RawHourData zero fixture")
    func testHourZero() {
        let zero = RawHourData.zero
        #expect(zero.values.count == 24)
        #expect(zero.values.allSatisfy { $0 == 0 })
    }

    @Test("RawBreakdownData initialization")
    func testBreakdownInit() {
        let data = RawBreakdownData(
            typeMeters: 1000,
            totalMeters: 5000,
            typeCount: 2,
            totalCount: 10,
            typeDurationSecs: 600,
            totalDurationSecs: 3600
        )
        #expect(data.typeMeters == 1000)
        #expect(data.totalMeters == 5000)
        #expect(data.typeCount == 2)
        #expect(data.totalCount == 10)
        #expect(data.typeDurationSecs == 600)
        #expect(data.totalDurationSecs == 3600)
    }

    @Test("RawWeekInsights empty fixture")
    func testWeekInsightsEmpty() {
        let empty = RawWeekInsights.empty
        #expect(empty.totalMeters == 0)
        #expect(empty.totalDurationSecs == 0)
        #expect(empty.tripCount == 0)
        #expect(empty.avgTripMeters == 0)
        #expect(empty.avgTripDurationSecs == 0)
        #expect(empty.longestTripMeters == 0)
        #expect(empty.longestTripDurationSecs == 0)
        #expect(empty.busiestDowByCount == -1)
    }
}
