import SwiftUI

public struct LayoutGuide {
    // MARK: - Breakpoints (bins based on iPhone logical sizes SE2+ and iPad)
    public enum Breakpoint: String, Equatable {
        case mini  // iPhone SE (2nd/3rd gen) iPhone 11 Pro
        case standard  // iPhone 14
        case large  // iPhone 15 Pro
        case xLarge  //physical 16 pro max
        case ipad  // iPad and large windows

        var id: String { rawValue.capitalized }

        static func from(size: CGSize) -> Breakpoint {
            // Use the shorter side so bins are stable in both orientations
            let minDim = min(max(size.width, 1), max(size.height, 1))

            if minDim >= 700 { return .ipad }  // iPad and large windows
            if minDim >= 415 { return .xLarge }  // 428–430
            if minDim >= 391 { return .large }  // 414
            if minDim >= 381 { return .standard }  // 390
            return .mini  // 375 (SE2/3 and similar)
        }
    }

    // MARK: - Core Dimensions
    public let widthDimension: Dimension
    public let heightDimension: Dimension

    public var width: Dimension { widthDimension }
    public var height: Dimension { heightDimension }

    // Derived flags
    public let breakpoint: Breakpoint

    // MARK: - Safe Area
    public let safeArea: EdgeInsets

    public var topSafeInset: CGFloat {
        switch breakpoint {
        case .mini:
            let baseline: CGFloat = 22
            return max(safeArea.top + 2, baseline)

        case .standard, .large, .xLarge, .ipad:
            // Notched devices and iPad: add tuned extra on top of the system safe area.
            let extra: CGFloat = {
                switch breakpoint {
                case .ipad: return height.pct(0.03)
                case _: return 0
                }
            }()
            return safeArea.top + extra
        }
    }
    
    public var titleHeight: CGFloat {
        switch breakpoint {
        case .mini:     52
        case .standard: 58
        case .large:    62
        case .xLarge:   64
        case .ipad:     64
        }
    }
    
    public var topButtonInset: CGFloat {
        return topSafeInset + ((titleHeight - buttonHeight) / 2)
    }

    public var bottomSafeInset: CGFloat {
        let extra =
            switch breakpoint {
            case .mini: height.pct(0.055)
            case .ipad: height.pct(0.05)
            case _: height.pct(0.01)
            }
        return safeArea.bottom + extra
    }

    public var attributionLeadingInset: CGFloat {
        switch breakpoint {
        case .mini: return width.pct(0.001)
        case _: return 0.0
        }
    }

    public var attributionBottomInset: CGFloat {
        switch breakpoint {
        case .mini: return height.pct(0.001)
        case _: return 0.0
        }
    }

    public var leadingSafeInset: CGFloat { safeArea.leading }
    public var trailingSafeInset: CGFloat { safeArea.trailing }

    // Natural horizontal padding to keep full-width elements off the screen edges
    public var horizontalEdgeInset: CGFloat {
        switch breakpoint {
        case .mini:     return 12
        case .standard: return 14
        case .large:    return 16
        case .xLarge:   return 18
        case .ipad:     return 24
        }
    }

    // MARK: - Animation Tokens
    public let animationDurations: AnimationDurations

    // Corner radius scales with tier and width (390-pt baseline)
    public var cornerRadius: CGFloat {
        let base: CGFloat = 22
        let tierScale: CGFloat =
            switch breakpoint {
            case .mini: 0.95
            case .standard: 1.00
            case .large: 1.06
            case .xLarge: 1.12
            case .ipad: 1.18
            }
        let widthScale = min(max(width.value / 390.0, 0.9), 1.3)
        return base * tierScale * widthScale
    }
    
    
    
    // MARK: - Control Metrics (used by CustomButton)
    public var buttonWidth: CGFloat {
        switch breakpoint {
        case .mini: 44
        case .standard: 50
        case .large: 54
        case .xLarge: 56
        case .ipad: 56
        }
    }

    public var buttonHeight: CGFloat {
        switch breakpoint {
        case .mini: 44
        case .standard: 50
        case .large: 54
        case .xLarge: 56
        case .ipad: 56
        }
    }

    public var controlSize: ControlSize {
        switch breakpoint {
        case .mini: .small
        case .standard: .regular
        case .large: .regular
        case .xLarge: .regular
        case .ipad: .large
        }
    }

    // MARK: - Dynamic Context Bar Variables
    public var barWidth: CGFloat { flexibleWidth }
    public var halfBarWidth: CGFloat { flexibleWidth * 0.5 }

    // Overlay buttons inset from edges relative to available side space
    public var mainButtonInsets: CGFloat {
        let workingSpace = (width.value - halfBarWidth) / 2
        let negSpace = workingSpace - buttonWidth
        switch breakpoint {
        case .mini: return negSpace * 0.76
        case .standard: return negSpace * 0.80
        case .large: return negSpace * 0.85
        case .xLarge: return negSpace * 0.88
        case .ipad: return negSpace * 0.92
        }
    }

    // MARK: - Internals: Flexible sizing tuned per bin
    private var flexibleWidth: CGFloat {
        switch breakpoint {
        case .mini:
            return min(width.pct(0.96), height.pct(0.96))
        case .standard:
            return min(width.pct(0.92), height.pct(0.92))
        case .large:
            return min(width.pct(0.90), height.pct(0.90))
        case .xLarge:
            return min(width.pct(0.88), height.pct(0.88))
        case .ipad:
            return min(540, width.pct(0.70))
        }
    }

    public var flexibleHeight: CGFloat {
        switch breakpoint {
        case .mini:
            return min(width.pct(0.12), height.pct(0.12))
        case .standard:
            return min(width.pct(0.11), height.pct(0.11))
        case .large:
            return min(width.pct(0.10), height.pct(0.10))
        case .xLarge:
            return min(width.pct(0.09), height.pct(0.09))
        case .ipad:
            return min(width.pct(0.07), height.pct(0.07))
        }
    }

    // MARK: - Utilities
    @inlinable public func pct(_ fraction: CGFloat) -> CGFloat {
        widthDimension.value * fraction
    }

    public struct Dimension {
        public let value: CGFloat
        @inlinable public func pct(_ fraction: CGFloat) -> CGFloat {
            value * fraction
        }
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
    public static func make(for size: CGSize, safeArea: EdgeInsets)
        -> LayoutGuide
    {
        let w = max(size.width, 1)
        let h = max(size.height, 1)
        let bp = Breakpoint.from(size: CGSize(width: w, height: h))

        // Subtle animation tuning by tier
        let animationDurations: AnimationDurations = {
            switch bp {
            case .mini:
                return AnimationDurations(fast: 0.18, medium: 0.45, slow: 0.72)
            case .standard:
                return AnimationDurations(fast: 0.20, medium: 0.50, slow: 0.80)
            case .large:
                return AnimationDurations(fast: 0.20, medium: 0.52, slow: 0.82)
            case .xLarge:
                return AnimationDurations(fast: 0.22, medium: 0.54, slow: 0.84)
            case .ipad:
                return AnimationDurations(fast: 0.22, medium: 0.55, slow: 0.85)
            }
        }()

        return LayoutGuide(
            widthDimension: Dimension(value: w),
            heightDimension: Dimension(value: h),
            breakpoint: bp,
            safeArea: safeArea,
            animationDurations: animationDurations
        )
    }

    // MARK: - Private init
    private init(
        widthDimension: Dimension,
        heightDimension: Dimension,
        breakpoint: Breakpoint,
        safeArea: EdgeInsets,
        animationDurations: AnimationDurations
    ) {
        self.widthDimension = widthDimension
        self.heightDimension = heightDimension
        self.breakpoint = breakpoint
        self.safeArea = safeArea
        self.animationDurations = animationDurations
    }
}

private struct LayoutGuideKey: EnvironmentKey {
    static let defaultValue = LayoutGuide.make(
        for: .zero,
        safeArea: EdgeInsets()
    )
}

extension EnvironmentValues {
    public var layout: LayoutGuide {
        get { self[LayoutGuideKey.self] }
        set { self[LayoutGuideKey.self] = newValue }
    }
}

extension View {
    @inlinable public func layoutGuide(size: CGSize, safeArea: EdgeInsets)
        -> some View
    {
        environment(\.layout, LayoutGuide.make(for: size, safeArea: safeArea))
    }
}

