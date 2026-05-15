import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("Totals Tests")
struct TotalsTests {
    
    @Test("Initialization and Addition")
    func testTotals() {
        let t1 = Totals(totalDistanceM: 100, totalDurationS: 50, tripCount: 1)
        let t2 = Totals(totalDistanceM: 200, totalDurationS: 100, tripCount: 2)
        
        let sum = t1.adding(t2)
        #expect(sum.totalDistanceM == 300)
        #expect(sum.totalDurationS == 150)
        #expect(sum.tripCount == 3)
        #expect(sum.duration == 150)
        #expect(!sum.isEmpty)
        
        #expect(Totals.empty.isEmpty)
    }
}
