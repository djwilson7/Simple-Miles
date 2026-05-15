import Testing
@testable import SimpleMilesBackEnd
import Foundation
import SwiftUI

@Suite("TravelState Tests")
struct TravelStateTests {
    
    @Test("Display text and color")
    func testPresentation() {
        #expect(TravelState.idle.displayText == "Idle")
        #expect(TravelState.traveling.displayText == "Traveling")
        #expect(TravelState.paused.displayText == "Paused")
        
        #expect(TravelState.idle.color == .gray)
        #expect(TravelState.traveling.color == .green)
        #expect(TravelState.paused.color == .orange)
    }
}
