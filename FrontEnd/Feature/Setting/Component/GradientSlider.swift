import SwiftUI

/// A slider with a custom gradient track.
/// - Features:
///   - Configurable value via Binding and a ClosedRange
///   - Custom gradient for the track background
///   - Compact, pill-like track with continuous corners
///   - VoiceOver support via adjustable actions and labels
struct GradientTrackSlider: View {

    // MARK: - Inputs
    @Binding var value: Double
    let range: ClosedRange<Double>
    let gradient: LinearGradient

    // MARK: - Configuration
    let height: CGFloat = 30
    let trackHeight: CGFloat = 10
    let corner: CGFloat = 6

    // MARK: - Body
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(gradient)
                .frame(height: trackHeight)

            Slider(value: $value, in: range)
                .tint(.clear) // ensure the default accent track doesn't draw over the gradient
                .labelsHidden()
                .padding(.horizontal, -2)
        }
        .frame(height: height)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Value"))
        .accessibilityValue(Text(accessibilityValueText))
        .accessibilityAdjustableAction { direction in
            let step = (range.upperBound - range.lowerBound) / 20.0
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
        }
    }

    // MARK: - Accessibility
    private var accessibilityValueText: String {
        let percent = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
        let display = Int((percent * 100).rounded())
        return "\(display) percent"
    }
}

// MARK: - Color Utilities
extension Color {
    /// Convenience for HSB color creation.
    static func hsb(h: Double, s: Double, b: Double) -> Color {
        Color(
            UIColor(
                hue: CGFloat(h),
                saturation: CGFloat(s),
                brightness: CGFloat(b),
                alpha: 1
            )
        )
    }
}

// MARK: - Gradient Helpers
func hueGradient() -> LinearGradient {
    let stops = stride(from: 0.0, through: 1.0, by: 0.1).map {
        Gradient.Stop(color: .hsb(h: $0, s: 1, b: 1), location: $0)
    }
    return LinearGradient(
        gradient: Gradient(stops: stops),
        startPoint: .leading,
        endPoint: .trailing
    )
}

func saturationGradient(h: Double, b: Double) -> LinearGradient {
    LinearGradient(
        colors: [
            .hsb(h: h, s: 0, b: b),
            .hsb(h: h, s: 1, b: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

func brightnessGradient(h: Double, s: Double) -> LinearGradient {
    LinearGradient(
        colors: [
            .black,
            .hsb(h: h, s: s, b: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}
