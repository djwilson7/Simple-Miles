import SwiftUI

/// Centralized applier for your “glass + material + shape” recipe.
private struct MaterialApplier: ViewModifier {
    @EnvironmentObject private var settings: SettingsCenter

    /// If nil, we use settings.glassStyle (global). Otherwise, force a specific style.
    let overrideStyle: MaterialOverride?

    /// Your standard radius; passed in on init.
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        let style = overrideStyle ?? settings.materialOverride
        let shape = RoundedRectangle(cornerRadius: 44, style: .continuous)
        let color = SettingsCenter.shared.accentColor
        
        return Group {
            switch style {
            case .clear:
                // Clear chrome glass; your .glassEffect handles clipping via `in:`
                content
                    .background(color.opacity(0.15))
                    .clipShape(shape)
                    .glassEffect(.clear, in: shape)

            case .regular:
                // Default/regular chrome glass
                content
                    .background(color.opacity(0.15))
                    .clipShape(shape)
                    .glassEffect(in: shape)

            case .frosted:
                // No chrome; use deeper frost via ultraThin material bed
                content
                    .background(color.opacity(0.15))
                    .background(.ultraThinMaterial)
                    .clipShape(shape)

            case .none:
                // Solid card background, no material, no glass
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
    /// Apply the app-standard material treatment using the user's current setting.
    func applyMaterial() -> some View {
        return modifier(MaterialApplier(overrideStyle: nil, cornerRadius: 44))
    }

    /// Apply a specific material style for this view only (overrides the global setting).
    /// - Parameters:
    ///   - style: The explicit MaterialOverride to apply.
    func applyMaterial(_ style: MaterialOverride) -> some View {
        return modifier(MaterialApplier(overrideStyle: style, cornerRadius: 44))
    }
}
