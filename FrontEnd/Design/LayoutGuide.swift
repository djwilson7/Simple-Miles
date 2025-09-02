import SwiftUI

public struct LayoutGuide {
    // MARK: - Core Dimensions
    public let widthDimension: Dimension
    public let heightDimension: Dimension

    public var width: Dimension { widthDimension }
    public var height: Dimension { heightDimension }

    // MARK: - Tokens
    public let radii: Radii
    public let animationDurations: AnimationDurations

    // MARK: - Transitional Control Metrics (used by CustomButton)
    // NOTE: Consider migrating these to your semantic layout (uiBlock/uiStyle) and removing from here.
    public var buttonWidth: CGFloat { min(100, width.pct(0.15)) }
    public var buttonHeight: CGFloat { max(40, height.pct(0.05)) }

    // MARK: - Utilities
    @inlinable public func pct(_ fraction: CGFloat) -> CGFloat { widthDimension.value * fraction }

    public struct Dimension {
        public let value: CGFloat
        @inlinable public func pct(_ fraction: CGFloat) -> CGFloat { value * fraction }
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

    // MARK: - Factory
    public static func make(for size: CGSize) -> LayoutGuide {
        let w = max(size.width, 1)
        let h = max(size.height, 1)

        // Reference-driven scale:
        // rawScale normalizes to a 390pt baseline (roughly iPhone portrait width),
        // then clamped to 0.9...1.3 to keep visuals reasonable on extremes.
        let rawScale = w / 390.0
        let s = min(max(rawScale, 0.9), 1.3)

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
            radii: radii,
            animationDurations: animationDurations
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
