import SwiftUI

private struct MaterialApplier: ViewModifier {
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.layout) private var layout

    let overrideStyle: MaterialOverride?

    func body(content: Content) -> some View {
        let style = overrideStyle ?? settings.materialOverride
        let color = settings.accentColor

        return Group {
            switch style {
            case .clear:
                content
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: layout.cornerRadius))

            case .regular:
                content
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
                    .glassEffect(in: RoundedRectangle(cornerRadius: layout.cornerRadius))

            case .frosted:
                content
                    .background(color.opacity(0.15))
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))

            case .none:
                content
                    .background(
                        (color == .clear ? Color(.systemBackground) : color)
                            .opacity(1)
                            .saturation(0.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: layout.cornerRadius))
            }
        }
    }
}

extension View {
    func applyMaterial() -> some View {
        modifier(MaterialApplier(overrideStyle: nil))
    }

    func applyMaterial(_ style: MaterialOverride) -> some View {
        modifier(MaterialApplier(overrideStyle: style))
    }
}
