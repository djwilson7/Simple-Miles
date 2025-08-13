//
//  LayoutGuide.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/12/25.
//


//
//  LayoutGuide.swift
//  SimpleMiles
//
//  Central, device-aware layout guide + padding helpers.
//  The guide is injected via Environment and scales with the container size
//  (so previews, iPad split views, and rotations all adapt automatically).
//
//  Usage (top-level):
//  GeometryReader { geo in
//      MainView(...)
//          .layoutGuide(size: geo.size) // installs device-aware tokens
//  }
//
//  Usage (inside any subview):
//  @Environment(\.layout) private var layout
//  HStack(spacing: layout.spacing.l) { ... }
//  .appPadding(.vertical, layout.spacing.l) // top/bottom = L, sides = L/2
//

import SwiftUI

// MARK: - Central Layout Guide (Design Tokens + Size Awareness)
public struct LayoutGuide {
    // Container size
    public let widthDimension: Dimension
    public let heightDimension: Dimension

    /// Convenience accessors returning Dimension for width and height
    public var width: Dimension { widthDimension }
    public var height: Dimension { heightDimension }

    /// Scale relative to a 390pt baseline (roughly iPhone 14 width in points)
    public let scale: CGFloat

    // Public token groups (spacing, radii, animation durations)
    public let spacing: Spacing
    public let radii: Radii
    public let animationDurations: AnimationDurations
    
    // Inside LayoutGuide
    public var buttonWidth: CGFloat { width.pct(0.15) }  // 10% of view width
    public var buttonHeight: CGFloat { max(40, height.pct(0.05)) } // 5% of view height
    
    public var titleWidth: CGFloat { width.pct(0.5) }
    public var titleHeight: CGFloat { max(40, height.pct(0.05)) }
    // SpacerDimension for horizontal and vertical spacers
    public let spacer: SpacerDimension

    // Percent helper (e.g., layout.pct(0.05) == 5% of width)
    @inlinable public func pct(_ fraction: CGFloat) -> CGFloat { widthDimension.value * fraction }

    // Example token derived from width (use wherever you need a width-based spacing)
    @inlinable public var hStackSpace: CGFloat { pct(0.10) } // 10% of width

    // MARK: Nested Dimension struct
    public struct Dimension {
        public let value: CGFloat
        @inlinable public func pct(_ fraction: CGFloat) -> CGFloat { value * fraction }
    }

    // MARK: Nested SpacerDimension struct
    public struct SpacerDimension {
        public let horizontal: Dimension
        public let vertical: Dimension
    }

    // MARK: Tokens
    public struct Spacing {
        public let xs: CGFloat  // 4 * s
        public let s:  CGFloat  // 8 * s
        public let m:  CGFloat  // 12 * s
        public let l:  CGFloat  // 16 * s
        public let xl: CGFloat  // 24 * s
        public let xxl: CGFloat // 32 * s
    }

    public struct Radii {
        public let s: CGFloat   // e.g., small cards
        public let m: CGFloat
        public let l: CGFloat
        public let pill: CGFloat // e.g., circular/rounded bars
    }

    // Animation duration tokens
    public struct AnimationDurations {
        public let fast: Double
        public let medium: Double
        public let slow: Double
    }

    // Factory: builds a LayoutGuide from a given container size
    public static func make(for size: CGSize) -> LayoutGuide {
        let w = max(size.width, 1)
        let h = max(size.height, 1)

        // Scale around baseline; clamp so tiny phones don’t get comically small
        let rawScale = w / 390.0
        let s = min(max(rawScale, 0.9), 1.3)

        // 4pt grid scaled by s
        let base: CGFloat = 4 * s
        let spacing = Spacing(
            xs: base * 1,   // 4*s
            s:  base * 2,   // 8*s
            m:  base * 3,   // 12*s
            l:  base * 4,   // 16*s
            xl: base * 6,   // 24*s
            xxl: base * 8   // 32*s
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

// MARK: - Environment plumbing
private struct LayoutGuideKey: EnvironmentKey {
    /// Placeholder default value using `.zero` size.
    /// The layout guide must be installed at the root using `layoutGuide(size:)` with real container size.
    static let defaultValue = LayoutGuide.make(for: .zero)
}

public extension EnvironmentValues {
    /// Central, device-aware layout guide
    var layout: LayoutGuide {
        get { self[LayoutGuideKey.self] }
        set { self[LayoutGuideKey.self] = newValue }
    }
}

public extension View {
    /// Install a layout guide for this view subtree using a given size.
    /// Typically called once at the root that has access to container size.
    @inlinable func layoutGuide(size: CGSize) -> some View {
        environment(\.layout, LayoutGuide.make(for: size))
    }
}

// MARK: - Padding Presets
/// PaddingKind encodes *semantic* padding rules you can re-use app-wide.
/// These are asymmetric by design to standardize micro-spacing.
public enum PaddingKind: Equatable {
    /// Top/Bottom = base; Leading/Trailing = base/2
    case vertical
    /// Leading/Trailing = base; Top/Bottom = base/2
    case horizontal
    /// All edges = base
    case all
    /// No padding
    case none
    /// Custom edge values (escaped hatch when needed)
    case custom(top: CGFloat, leading: CGFloat, bottom: CGFloat, trailing: CGFloat)
}

public extension LayoutGuide {
    /// Compute EdgeInsets for a given kind and base value.
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
    /// Apply app-standard padding using the central LayoutGuide.
    /// - Parameters:
    ///   - kind: semantic padding variant (e.g., `.vertical`, `.horizontal`, `.all`)
    ///   - base: optional base value. If nil, uses `layout.spacing.m`.
    /// - Note: `.vertical` means top/bottom = base, sides = base/2. Vice-versa for `.horizontal`.
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
