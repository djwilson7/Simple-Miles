import SwiftUI

struct GradientTrackSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let gradient: LinearGradient
    let height: CGFloat = 30
    let trackHeight: CGFloat = 10
    let corner: CGFloat = 6

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner, style: .continuous)
                .fill(gradient)
                .frame(height: trackHeight)

            Slider(value: $value, in: range)
                .tint(.clear)
                .labelsHidden()
                .padding(.horizontal, -2)
        }
        .frame(height: height)
    }
}

extension Color {
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
