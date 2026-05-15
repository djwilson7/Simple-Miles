import Testing
@testable import SimpleMilesBackEnd
import Foundation

@Suite("ExtendDouble Tests")
struct ExtendDoubleTests {
    
    @Test("Conversion")
    func testConversion() {
        #expect(180.0.degreesToRadians == .pi)
        #expect(Double.pi.radiansToDegrees == 180.0)
    }
}
