import SwiftUI

public struct LayoutGuide {
    // MARK: - Core Dimensions
    public let widthDimension: Dimension
    public let heightDimension: Dimension

    public var width: Dimension { widthDimension }
    public var height: Dimension { heightDimension }
    
    public var isIpad: Bool { width.pct(1.0) >= 700 && height.pct(1.0) >= 700 }
    
    private var flexibleWidth: CGFloat {
        isIpad
        ? min(500, width.pct(0.7))
        : min(width.pct(0.95), height.pct(0.95))
    }
    
    public var flexibleHeight: CGFloat {
        isIpad
        ? min(width.pct(0.07), height.pct(0.07))
        : min(width.pct(0.1), height.pct(0.1))
    }
    
    // MARK: - Safe Area
    public let safeArea: EdgeInsets
    public var topSafeInset: CGFloat { safeArea.top + height.pct(0.02) }
    public var bottomSafeInset: CGFloat { safeArea.bottom + height.pct(0.05)}
    public var leadingSafeInset: CGFloat { safeArea.leading }
    public var trailingSafeInset: CGFloat { safeArea.trailing }

    // MARK: - Tokens
    public let animationDurations: AnimationDurations
    
    public var cornerRadius: CGFloat {
        let rawScale = width.value / 390.0
        let s = min(max(rawScale, 0.9), 1.3)
        return s * 24 //scale times desired radius
    }
    // MARK: - Transitional Control Metrics (used by CustomButton)
    // NOTE: Consider migrating these to your semantic layout (uiBlock/uiStyle) and removing from here.
    public var buttonWidth: CGFloat { isIpad ? 56 : 44 }
    public var buttonHeight: CGFloat { isIpad ? 56 : 44 }
    
    //Dynamic Context Bar Variables
    public var barWidth: CGFloat {
        flexibleWidth
    }
    
    //Title Bar Variables
    public var halfBarWidth: CGFloat {
        flexibleWidth * 0.5
    }
    
    public var mainButtonInsets: CGFloat {
        let workingSpace = (width.value - halfBarWidth) / 2
        let negSpace = workingSpace - buttonWidth
        return isIpad ? negSpace * 0.9 : negSpace * 0.8
    }
    
    
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
        public let corner: CGFloat
    }

    public struct AnimationDurations {
        public let fast: Double
        public let medium: Double
        public let slow: Double
    }

    // MARK: - Factory
    public static func make(for size: CGSize, safeArea: EdgeInsets) -> LayoutGuide {
        let w = max(size.width, 1)
        let h = max(size.height, 1)

        let animationDurations = AnimationDurations(
            fast: 0.2,
            medium: 0.5,
            slow: 0.8
        )

        return LayoutGuide(
            widthDimension: Dimension(value: w),
            heightDimension: Dimension(value: h),
            safeArea: safeArea,
            animationDurations: animationDurations
        )
    }
}

private struct LayoutGuideKey: EnvironmentKey {
    static let defaultValue = LayoutGuide.make(for: .zero, safeArea: EdgeInsets())
}

public extension EnvironmentValues {
    var layout: LayoutGuide {
        get { self[LayoutGuideKey.self] }
        set { self[LayoutGuideKey.self] = newValue }
    }
}

public extension View {
    @inlinable func layoutGuide(size: CGSize, safeArea: EdgeInsets) -> some View {
        environment(\.layout, LayoutGuide.make(for: size, safeArea: safeArea))
    }
}

