import SwiftUI

// MARK: - Roles
enum UIStyleRole {
    case title       // page/tab titles
    case section     // section headers
    case row         // standard content rows
    case info        // inline info / helper text
}

// MARK: - Spacing Tokens
private enum Layout {
    static let grid: CGFloat = 4  // base unit

    static var titleV: CGFloat   { 3 * grid }  // 12
    static var titleH: CGFloat   { 4 * grid }  // 16

    static var sectionV: CGFloat { 2 * grid }  // 8
    static var sectionH: CGFloat { 3 * grid }  // 12

    static var rowV: CGFloat     { 1 * grid }  // 4
    static var rowH: CGFloat     { 2 * grid }  // 8
}

// MARK: - Typography Tokens
private enum Typography {
    // Using your choices intentionally
    static var title: Font   { .headline.weight(.semibold) }
    static var section: Font { .subheadline.weight(.semibold) }
    static var row: Font     { .caption }
    static var info: Font    { .caption.weight(.semibold) }
}

// MARK: - Text-only modifier (no padding)
private struct SemanticText: ViewModifier {
    let role: UIStyleRole
    func body(content: Content) -> some View {
        switch role {
        case .title:
            content.font(Typography.title).lineLimit(1)
        case .section:
            content.font(Typography.section).lineLimit(1)
        case .row:
            content.font(Typography.row)
        case .info:
            content.font(Typography.info)
        }
    }
}

// MARK: - Block-only modifier (padding only)
private struct SemanticBlock: ViewModifier {
    let role: UIStyleRole
    func body(content: Content) -> some View {
        switch role {
        case .title:
            content
                .padding(.vertical, Layout.titleV)
                .padding(.horizontal, Layout.titleH)
        case .section:
            content
                .padding(.top, Layout.sectionV)
                .padding(.bottom, Layout.rowV)
                .padding(.horizontal, Layout.sectionH)
        case .row:
            content
                .padding(.vertical, Layout.rowV)
                .padding(.horizontal, Layout.rowH)
        case .info:
            content // intentionally no padding for inline info blocks
        }
    }
}

// MARK: - Combined modifier (font + padding)
private struct SemanticStyle: ViewModifier {
    let role: UIStyleRole
    func body(content: Content) -> some View {
        content
            .modifier(SemanticText(role: role))
            .modifier(SemanticBlock(role: role))
    }
}

// MARK: - Sugar
extension View {
    /// Font + padding
    func uiStyle(_ role: UIStyleRole) -> some View {
        modifier(SemanticStyle(role: role))
    }

    /// Font only
    func uiText(_ role: UIStyleRole) -> some View {
        modifier(SemanticText(role: role))
    }

    /// Padding only
    func uiBlock(_ role: UIStyleRole) -> some View {
        modifier(SemanticBlock(role: role))
    }

    /// Optional helper for nudging without breaking consistency
    func uiInset(vertical v: CGFloat? = nil, horizontal h: CGFloat? = nil) -> some View {
        padding(.vertical, v ?? 0).padding(.horizontal, h ?? 0)
    }
}
