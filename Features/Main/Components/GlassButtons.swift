import SwiftUI
import UIKit

struct SystemControlButton: View {
    @Environment(\.layout) private var layout
    let label: AnyView
    let opacity: Double
    let color: Color
    let action: () -> Void

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
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            action()
        }) {
            ZStack {
                Color.white.opacity(0.001)
                    .clipShape(Circle())

                label
                    .foregroundStyle(color)
            }
            .frame(width: layout.buttonWidth, height: layout.buttonHeight)
            .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
            .opacity(opacity)
        }
        .buttonStyle(.plain)
        .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        .glassEffect(in: RoundedRectangle(cornerRadius: layout.radii.pill))
        .opacity(opacity)
    }
}
