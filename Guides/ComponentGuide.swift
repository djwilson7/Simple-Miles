//
//  ComponentGuide.swift
//  SimpleMiles
//
//  File Guide for "Components" (Reusable SwiftUI Views & Modifiers)
//
//  Purpose:
//  A concise, copy‑pasteable guide for creating reusable SwiftUI components
//  (controls, modifiers, helpers). Keep them focused, composable, and easy to test.
//  Favor small, stateless views with explicit inputs.
//
//  Scope:
//  - “Components” live below feature Views and above primitives.
//  - Examples: buttons, pickers, indicators, cards, reusable modifiers,
//    environment keys, and layout utilities.
//
// MARK: - What belongs in a Component file
/*
 - One primary reusable piece (e.g., struct CustomButton: View or a ViewModifier)
 - Minimal state; inputs provided as let properties or @Binding where needed
 - No business logic; render and user interaction only
 - Accessibility (labels, traits) and haptics considered
 - Light theming via Environment (e.g., colorScheme, custom layout env)
 - Preview(s) at the bottom when helpful
*/

// MARK: - Section Order (for all Component files)
/*
 1) Imports (Apple first, then project)
 2) File-level doc (what this component does)
 3) Primary type (struct ...: View / struct ...: ViewModifier)
 4) Inputs / Bindings / Configuration
 5) Environment deps (e.g., @Environment(\.layout))
 6) Body
 7) Subviews (private computed some View)
 8) Accessibility / Haptics (inline or helpers)
 9) Previews (#Preview)
*/

// MARK: - Naming & API Design
/*
 - Name for intent (CustomButton, SettingCard, PageIndicators)
 - Prefer init with clear labels; provide sensible defaults
 - Use @Binding only when the component needs two-way data flow
 - Expose simple callbacks (onTap, onChange) for actions
 - Keep styling customizable via parameters (color, size, variant)
*/

// MARK: - Access Control
/*
 - Mark the component public/internal based on target usage
 - Keep helpers private/fileprivate
 - Avoid leaking types unless intended (nest helpers if local-only)
*/

// MARK: - Performance & State
/*
 - Prefer value types and simple computed views
 - Avoid unnecessary @State; derive from inputs where possible
 - Use .id(), .animation(value:) deliberately to avoid churn
 - Consider EquatableView if rendering with large inputs
*/

// MARK: - Accessibility
/*
 - Provide .accessibilityLabel, .accessibilityAddTraits
 - Respect Dynamic Type and contrast (avoid color-only signals)
 - Ensure hit targets meet recommended sizes
*/

// MARK: - Copy/Paste Template: Reusable Button
/*
import SwiftUI

/// A reusable button with optional icon, visibility control, and haptics.
struct CustomButton: View {

    // MARK: - Inputs
    let isVisible: Bool
    let color: Color
    let action: () -> Void
    let icon: String
    var text: String? = nil
    var haptic: UIImpactFeedbackGenerator.FeedbackStyle? = .soft

    // MARK: - Environment
    @Environment(\.layout) private var layout

    // MARK: - Body
    var body: some View {
        Group {
            if isVisible {
                Button(action: tap) {
                    label
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                .foregroundStyle(color)
                .accessibilityLabel(Text(accessibilityText))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isVisible)
    }

    // MARK: - Subviews
    private var label: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .imageScale(.medium)
            if let text {
                Text(text)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
    }

    // MARK: - Actions
    private func tap() {
        if let style = haptic {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
        action()
    }

    // MARK: - Accessibility
    private var accessibilityText: String {
        text ?? icon.replacingOccurrences(of: ".", with: " ")
    }
}
*/

// MARK: - Copy/Paste Template: ViewModifier
/*
import SwiftUI

/// Applies a consistent material + corner radius treatment to blocks.
struct CardMaterial: ViewModifier {
    @Environment(\.layout) private var layout
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: layout.radii.card))
    }
}

extension View {
    func applyMaterial() -> some View { modifier(CardMaterial()) }
}
*/

// MARK: - Copy/Paste Template: PreferenceKey
/*
import SwiftUI

/// Reports a child view's size to ancestors.
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        // Choose the strategy appropriate for your layout; here we keep the max.
        value = CGSize(width: max(value.width, next.width), height: max(value.height, next.height))
    }
}
*/

// MARK: - Copy/Paste Template: EnvironmentKey
/*
import SwiftUI

/// Example custom environment for layout metrics used across components.
struct LayoutEnvironment {
    struct Radii {
        let pill: CGFloat = 16
        let card: CGFloat = 12
    }
    let radii = Radii()
    func widthPct(_ pct: CGFloat, in total: CGFloat) -> CGFloat { total * pct }
}

private struct LayoutKey: EnvironmentKey {
    static let defaultValue = LayoutEnvironment()
}

extension EnvironmentValues {
    var layout: LayoutEnvironment {
        get { self[LayoutKey.self] }
        set { self[LayoutKey.self] = newValue }
    }
}
*/

// MARK: - Copy/Paste Template: Equatable Component
/*
import SwiftUI

/// Use Equatable when a component re-renders with large inputs frequently.
struct Badge: View, Equatable {
    let text: String
    let color: Color

    static func == (lhs: Badge, rhs: Badge) -> Bool {
        lhs.text == rhs.text && lhs.color == rhs.color
    }

    var body: some View {
        Text(text)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
*/

// MARK: - Testing Components
/*
 - Keep rendering logic pure; avoid side effects in body
 - For stateful components, separate appearance from behavior (inject callbacks)
 - Use SwiftUI previews for quick iteration; add Swift Testing for layout/state where feasible

 import Testing
 @Suite("CustomButton")
 struct CustomButtonTests {
     @Test
     func tapCallsAction() async throws {
         var tapped = false
         let button = CustomButton(isVisible: true, color: .blue, action: { tapped = true }, icon: "gear")
         // Render in a test harness if desired; here we just verify the function is callable.
         button.action()
         #expect(tapped == true)
     }
 }
*/

// MARK: - Common MARK Tags (for Components)
/*
 // MARK: - Inputs
 // MARK: - Environment
 // MARK: - Body
 // MARK: - Subviews
 // MARK: - Actions
 // MARK: - Accessibility
 // MARK: - Previews
*/
