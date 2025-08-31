import SwiftUI
import UIKit

struct CustomButton: View {
    @Environment(\.layout) private var layout

    let icon: String?
    let text: String?
    let isVisible: Bool
    let color: Color
    let action: () -> Void

    init(
        isVisible: Bool = true,
        color: Color = .primary,
        action: @escaping () -> Void,
        icon: String? = nil,
        text: String? = nil
    ) {
        self.icon = (icon?.isEmpty == true) ? nil : icon
        self.text = (text?.isEmpty == true) ? nil : text
        self.isVisible = isVisible
        self.color = color
        self.action = action
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.radii.pill)

        Button(action: {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            TripSubMenuViewModel.shared.isVisible = false
            action()
        }) {
            content
                .uiBlock(.row)
                .frame(minWidth: layout.buttonWidth, minHeight: layout.buttonHeight, alignment: .center)
        }
        .buttonStyle(.plain)
        .uiText(.title)
        .glassEffect(.clear, in: shape)
        .clipShape(shape)
        .contentShape(shape)
        .scaleEffect(isVisible ? 1.0 : 0.01, anchor: .center) // avoid 0.001 jitters
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        // Center-lock everything; show either HStack(icon+text), icon alone, or text alone.
        if let icon, let text {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(text)
                    .foregroundStyle(color)
            }
            .frame(alignment: .center)
            .compositingGroup()
            .accessibilityLabel(Text(text))
        } else if let icon {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(alignment: .center)
                .compositingGroup()
                .accessibilityLabel(Text(iconDescription(from: icon)))
        } else if let text {
            Text(text)
                .foregroundStyle(color)
                .frame(alignment: .center)
                .compositingGroup()
                .accessibilityLabel(Text(text))
        } else {
            // Nothing provided: keep hit area stable, but render nothing
            Color.clear
        }
    }

    // Basic mapping for common SF Symbols -> readable labels (fallback: raw name)
    private func iconDescription(from name: String) -> String {
        switch name {
        case "chevron.left":  return "Back"
        case "chevron.right": return "Next"
        case "gobackward":    return "Recenter"
        default:              return name.replacingOccurrences(of: ".", with: " ")
        }
    }
}
