import SwiftUI

enum UIStyleRole {
    case title
    case section
    case row
    case info
}

private enum Layout {
    static let grid: CGFloat = 4

    static var titleV: CGFloat   { 3 * grid }
    static var titleH: CGFloat   { 4 * grid }

    static var sectionV: CGFloat { 2 * grid }
    static var sectionH: CGFloat { 3 * grid }

    static var rowV: CGFloat     { 1 * grid }
    static var rowH: CGFloat     { 2 * grid }
}

private enum Typography {
    static func title(isIpad: Bool) -> Font { isIpad ? .title2 : .headline }
    static var section: Font { .subheadline.weight(.semibold) }
    static var row: Font     { .caption }
    static var info: Font    { .caption.weight(.semibold) }
}

private struct SemanticText: ViewModifier {
    @Environment(\.layout) private var layout
    let role: UIStyleRole

    func body(content: Content) -> some View {
        switch role {
        case .title:
            content.font(Typography.title(isIpad: layout.isIpad)).lineLimit(1)
        case .section:
            content.font(Typography.section).lineLimit(1)
        case .row:
            content.font(Typography.row)
        case .info:
            content.font(Typography.info)
        }
    }
}

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
            content
        }
    }
}

private struct SemanticStyle: ViewModifier {
    let role: UIStyleRole
    func body(content: Content) -> some View {
        content
            .modifier(SemanticText(role: role))
            .modifier(SemanticBlock(role: role))
    }
}

extension View {
    func uiStyle(_ role: UIStyleRole) -> some View {
        modifier(SemanticStyle(role: role))
    }

    func uiText(_ role: UIStyleRole) -> some View {
        modifier(SemanticText(role: role))
    }

    func uiBlock(_ role: UIStyleRole) -> some View {
        modifier(SemanticBlock(role: role))
    }

    func uiInset(vertical v: CGFloat? = nil, horizontal h: CGFloat? = nil) -> some View {
        padding(.vertical, v ?? 0).padding(.horizontal, h ?? 0)
    }
}
