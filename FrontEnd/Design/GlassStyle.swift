import SwiftUI

private struct MaterialBase<S: Shape>: ViewModifier {
    @EnvironmentObject private var settings: SettingsManager
    @Environment(\.layout) private var layout

    let overrideStyle: MaterialOverride?
    let shape: S

    func body(content: Content) -> some View {
        let style = overrideStyle ?? settings.materialOverride
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

private struct DefaultMaterialApplier: ViewModifier {
    @Environment(\.layout) private var layout
    let overrideStyle: MaterialOverride?

    func body(content: Content) -> some View {
        content.modifier(MaterialBase(overrideStyle: overrideStyle, shape: RoundedRectangle(cornerRadius: layout.cornerRadius)))
    }
}

extension View {
    func applyMaterial() -> some View {
        modifier(DefaultMaterialApplier(overrideStyle: nil))
    }

    func applyMaterial(_ style: MaterialOverride) -> some View {
        modifier(DefaultMaterialApplier(overrideStyle: style))
    }

    func applyMaterial<S: Shape>(in shape: S) -> some View {
        modifier(MaterialBase(overrideStyle: nil, shape: shape))
    }

    func applyMaterial<S: Shape>(_ style: MaterialOverride, in shape: S) -> some View {
        modifier(MaterialBase(overrideStyle: style, shape: shape))
    }
}
