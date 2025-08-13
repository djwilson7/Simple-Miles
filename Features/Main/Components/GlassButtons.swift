import SwiftUI

struct SystemControlButton: View {
    @Environment(\.layout) private var layout
    let label: AnyView
    let opacity: Double
    let color: Color
    let action: () -> Void

    // Provide default values including color
    init(
        opacity: Double = 1.0,
        color: Color = .primary,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) {
        self.label = AnyView(label())
        self.opacity = opacity
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.white.opacity(0.001)
                    .clipShape(Circle())

                label
                    .foregroundStyle(color)
            }
            .opacity(opacity)
            .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        }
        .buttonStyle(.plain)
    }
}


#Preview("SystemControlButton Examples") {
    VStack(spacing: 32) {
        SystemControlButton(opacity: 1.0, color: .yellow, action: {
            print("Gear tapped")
        }) {
            Image(systemName: "gear")
                .font(.system(size: 30, weight: .medium))
        }
        .glassEffect(.clear)
        .background(Color.clear.opacity(0.01))

        SystemControlButton(opacity: 0.5, color: .accentColor, action: {
            print("Back tapped")
        }) {
            Image(systemName: "chevron.backward")
                .font(.system(size: 30, weight: .medium))
        }
        .glassEffect(.clear)
    }
    .padding()
    .background(Color.black.opacity(0.9))
}
