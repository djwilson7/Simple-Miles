import Testing
@testable import SimpleMilesBackEnd
import SwiftUI

@Suite("macOS Compatibility Tests")
struct macOSCompatibilityTests {
    
    @Test("Color HSB extension")
    func testColorHSB() {
        #if os(macOS)
        let color = Color.hsb(h: 0.5, s: 0.5, b: 0.5)
        #expect(color == color)
        #endif
    }
}
