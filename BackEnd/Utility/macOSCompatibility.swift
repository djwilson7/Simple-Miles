import SwiftUI

#if os(macOS)
// Missing protocol for macOS testing
protocol SegmentedPickerOption: CaseIterable, Identifiable, Hashable {}

// Missing extension for macOS testing
extension Color {
    static func hsb(h: Double, s: Double, b: Double) -> Color {
        return Color(hue: h, saturation: s, brightness: b)
    }
}
#else
// On iOS, these are expected to be provided by the FrontEnd
#endif
