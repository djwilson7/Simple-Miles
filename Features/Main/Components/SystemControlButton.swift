import SwiftUI
import UIKit

struct SystemControlButton: View {
    @Environment(\.layout) private var layout
    let label: AnyView
    let isVisible: Bool
    let color: Color
    let action: () -> Void

    init(
        isVisible: Bool = true,
        color: Color = .primary,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> some View
    ) {
        self.label = AnyView(label())
        self.isVisible = isVisible
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            TripSubMenuViewModel.shared.isVisible = false
            action()
        }) {
            ZStack {
                Color.white.opacity(0.001)
                    .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))

                label
                    .foregroundStyle(color)
                    .scaleEffect(isVisible ? 1.0 : 0.001)
                    .animation(.easeInOut(duration: 0.25), value: isVisible)
            }
        }
        .buttonStyle(.plain)
        .uiText(.title)
        .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: layout.radii.pill))
        .scaleEffect(isVisible ? 1.0 : 0.001)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
    }
}
