import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("Logging Tests")
struct LoggingTests {
    
    @Test("Log function execution")
    func testLog() {
        Log("Test message")
        // Verified it doesn't crash
        #expect(Bool(true))
    }
}
