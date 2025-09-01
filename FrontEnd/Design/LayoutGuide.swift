import SwiftUI

public struct LayoutGuide {
    public let widthDimension: Dimension
    public let heightDimension: Dimension

    public var width: Dimension { widthDimension }
    public var height: Dimension { heightDimension }

    public let scale: CGFloat

    public let spacing: Spacing
    public let radii: Radii
    public let animationDurations: AnimationDurations
    
    public var buttonWidth: CGFloat { min(100, width.pct(0.15)) }
    public var buttonHeight: CGFloat { max(40, height.pct(0.05)) }
    
    public var elementWidth: CGFloat { min(500, width.pct(0.5)) }
    public var titleHeight: CGFloat { max(40, height.pct(0.05)) }
    public var titleButtonOffset: CGFloat {min(400, width.pct(0.34))}
    public var contextButtonOffset: CGFloat { min (400, width.pct(0.37)) }
    
    public var controlButtonsPadding: CGFloat { width.pct(0.01) }
    
    public let spacer: SpacerDimension

    @inlinable public func pct(_ fraction: CGFloat) -> CGFloat { widthDimension.value * fraction }

    @inlinable public var hStackSpace: CGFloat { pct(0.10) }

    public struct Dimension {
        public let value: CGFloat
        @inlinable public func pct(_ fraction: CGFloat) -> CGFloat { value * fraction }
    }

    public struct SpacerDimension {
        public let horizontal: Dimension
        public let vertical: Dimension
    }

    public struct Spacing {
        public let xs: CGFloat
        public let s:  CGFloat
        public let m:  CGFloat
        public let l:  CGFloat
        public let xl: CGFloat
        public let xxl: CGFloat
    }

    public struct Radii {
        public let s: CGFloat
        public let m: CGFloat
        public let l: CGFloat
        public let pill: CGFloat
    }

    public struct AnimationDurations {
        public let fast: Double
        public let medium: Double
        public let slow: Double
    }

    public static func make(for size: CGSize) -> LayoutGuide {
        let w = max(size.width, 1)
        let h = max(size.height, 1)

        let rawScale = w / 390.0
        let s = min(max(rawScale, 0.9), 1.3)

        let base: CGFloat = 4 * s
        let spacing = Spacing(
            xs: base * 1,
            s:  base * 2,
            m:  base * 3,
            l:  base * 4,
            xl: base * 6,
            xxl: base * 8
        )

        let radii = Radii(
            s:  8 * s,
            m: 12 * s,
            l: 20 * s,
            pill: 44 * s
        )

        let animationDurations = AnimationDurations(
            fast: 0.2,
            medium: 0.5,
            slow: 0.8
        )

        return LayoutGuide(
            widthDimension: Dimension(value: w),
            heightDimension: Dimension(value: h),
            scale: s,
            spacing: spacing,
            radii: radii,
            animationDurations: animationDurations,
            spacer: SpacerDimension(
                horizontal: Dimension(value: w),
                vertical: Dimension(value: h)
            )
        )
    }
}

private struct LayoutGuideKey: EnvironmentKey {
    static let defaultValue = LayoutGuide.make(for: .zero)
}

public extension EnvironmentValues {
    var layout: LayoutGuide {
        get { self[LayoutGuideKey.self] }
        set { self[LayoutGuideKey.self] = newValue }
    }
}

public extension View {
    @inlinable func layoutGuide(size: CGSize) -> some View {
        environment(\.layout, LayoutGuide.make(for: size))
    }
}

public enum PaddingKind: Equatable {
    case vertical
    case horizontal
    case all
    case none
    case custom(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat)
}

public extension LayoutGuide {
    @inlinable func edgeInsets(for kind: PaddingKind, base: CGFloat) -> EdgeInsets {
        switch kind {
        case .vertical:
            return EdgeInsets(top: base, leading: base / 2, bottom: base, trailing: base / 2)
        case .horizontal:
            return EdgeInsets(top: base / 2, leading: base, bottom: base / 2, trailing: base)
        case .all:
            return EdgeInsets(top: base, leading: base, bottom: base, trailing: base)
        case .none:
            return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        case let .custom(t, l, b, r):
            return EdgeInsets(top: t, leading: l, bottom: b, trailing: r)
        }
    }
}

public extension View {
    func appPadding(_ kind: PaddingKind, _ base: CGFloat? = nil) -> some View {
        modifier(AppPaddingModifier(kind: kind, base: base))
    }
}

private struct AppPaddingModifier: ViewModifier {
    @Environment(\.layout) private var layout
    let kind: PaddingKind
    let base: CGFloat?

    func body(content: Content) -> some View {
        let b = base ?? layout.spacing.m
        let insets = layout.edgeInsets(for: kind, base: b)
        return content.padding(insets)
    }
}
