import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("Small Models Tests")
struct SmallModelsTests {
    
    @Test("SortedTripTotalsModel")
    func testSortedTotals() async throws {
        let model = SortedTripTotalsModel(tripType: .business)
        #expect(model.tripType == .business)
        
        // Wait a bit for the global queue + main queue dispatch in refreshFromStore
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Even if empty, it should be initialized
        #expect(model.totalDistance >= 0)
        #expect(model.totalDuration >= 0)
        #expect(model.tripCount >= 0)
    }
}

@Suite("UserDefaultKeys Tests")
struct UserDefaultKeysTests {
    @Test("Raw values match expected strings")
    func testRawValues() {
        #expect(UserDefaultKeys.lastKnownLocation.rawValue == "lastKnownLocation")
        #expect(UserDefaultKeys.lastNotificationDate.rawValue == "lastNotificationDate")
        #expect(UserDefaultKeys.cameraAltitude.rawValue == "cameraAltitude")
    }
}

@Suite("MainStateManager Tests", .serialized)
struct MainStateManagerTests {
    
    @MainActor
    @Test("State transition and cases")
    func testMainState() {
        let manager = MainStateManager.shared
        for state in MainStateManager.MainState.allCases {
            manager.state = state
            #expect(manager.state == state)
            #expect(state.id == state.rawValue)
        }
    }
}
