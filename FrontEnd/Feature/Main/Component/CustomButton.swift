import SwiftUI
import UIKit

/// A reusable button with optional icon and text that adopts app-wide layout metrics and styling.
/// - Features:
///   - Visibility control via `isVisible` (scales and disables hit-testing when hidden)
///   - Enable/disable control via `isEnabled` (uses SwiftUI `.disabled`, adds subtle grayscale when disabled)
///   - Optional icon and/or text
///   - Consistent sizing using `LayoutGuide` (buttonWidth/Height)
///   - Material background, pill corner radius, and app typography via project modifiers
///   - Haptic feedback on tap (configurable)
///   - Accessibility label derived from text or icon name
struct CustomButton: View {

    // MARK: - Environment
    @Environment(\.layout) private var layout

    // MARK: - Inputs
    let icon: String?
    let text: String?
    let isVisible: Bool
    let isEnabled: Bool
    let color: Color
    let action: () -> Void
    let haptic: UIImpactFeedbackGenerator.FeedbackStyle?

    // MARK: - Init
    init(
        isVisible: Bool = true,
        isEnabled: Bool = true,
        color: Color = .primary,
        action: @escaping () -> Void,
        icon: String? = nil,
        text: String? = nil,
        haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .soft
    ) {
        self.icon = (icon?.isEmpty == true) ? nil : icon
        self.text = (text?.isEmpty == true) ? nil : text
        self.isVisible = isVisible
        self.isEnabled = isEnabled
        self.color = color
        self.action = action
        self.haptic = haptic
    }

    var body: some View {
        let shape = Circle()

        Button(
            action: {
                if let style = haptic {
                    UIImpactFeedbackGenerator(style: style).impactOccurred()
                }
                action()
            }
        ) {
            ZStack {
                shape
                    .fill(Color.clear)
                    .applyMaterial(in: shape)
                
                content
                    .uiText(.title)
            }
            .frame(width: layout.buttonWidth, height: layout.buttonHeight)
            .contentShape(shape)
            .clipShape(shape)
            .grayscale(isEnabled ? 0.0 : 0.6)
        }
        .buttonStyle(.plain)
        .scaleEffect(isVisible ? 1.0 : 0.01, anchor: .center)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .disabled(!isEnabled || !isVisible)
        .accessibilityLabel(Text(accessibilityText))
        .animation(.easeInOut(duration: 0.25), value: isVisible)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    // MARK: - Subviews
    @ViewBuilder
    private var content: some View {
        if let icon, let text {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(text)
                    .foregroundStyle(color)
            }
            .frame(alignment: .center)
            .compositingGroup()
        } else if let icon {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(alignment: .center)
                .compositingGroup()
        } else if let text {
            Text(text)
                .foregroundStyle(color)
                .frame(alignment: .center)
                .compositingGroup()
        } else {
            Color.clear
        }
    }

    // MARK: - Accessibility
    private var accessibilityText: String {
        if let text, !text.isEmpty { return text }
        if let icon, !icon.isEmpty { return iconDescription(from: icon) }
        return "Button"
    }

    private func iconDescription(from name: String) -> String {
        switch name {
        case "chevron.left":  return "Back"
        case "chevron.right": return "Next"
        case "gobackward":    return "Recenter"
        default:              return name.replacingOccurrences(of: ".", with: " ")
        }
    }
}
