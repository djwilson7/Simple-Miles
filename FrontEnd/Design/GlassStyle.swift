import SwiftUI

private struct MaterialApplier: ViewModifier {
    @EnvironmentObject private var settings: SettingsManager

    let overrideStyle: MaterialOverride?

    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let style = overrideStyle ?? settings.materialOverride
        let shape = RoundedRectangle(cornerRadius: 44, style: .continuous)
        let color = settings.accentColor
        
        return Group {
            switch style {
            case .clear:
                content
                    .background(color.opacity(0.15))
                    .clipShape(shape)
                    .glassEffect(.clear, in: shape)

            case .regular:
                content
                    .background(color.opacity(0.15))
                    .clipShape(shape)
                    .glassEffect(in: shape)

            case .frosted:
                content
                    .background(color.opacity(0.15))
                    .background(.ultraThinMaterial)
                    .clipShape(shape)

            case .none:
                content
                    .background(
                        (color == .clear ? Color(.systemBackground) : color)
                            .opacity(1)
                            .saturation(0.5)
                    )
                    .clipShape(shape)
            }
        }
    }

}

extension View {
    func applyMaterial() -> some View {
        return modifier(MaterialApplier(overrideStyle: nil, cornerRadius: 44))
    }

    func applyMaterial(_ style: MaterialOverride) -> some View {
        return modifier(MaterialApplier(overrideStyle: style, cornerRadius: 44))
    }
}
