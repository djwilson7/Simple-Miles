import SwiftUI
import Foundation
import UIKit

private struct RowHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TripStatusView: View {
    @Environment(\.layout) private var layout
    @ObservedObject var viewModel = TripStatusViewModel.shared
    @State private var rowHeight: CGFloat = 0
    
    var body: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                StatusRowBuilder(page: page)
                    .tag(index)
                    .frame(width: layout.width.pct(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: layout.width.pct(0.8), height: layout.height.pct(0.2))
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onChange(of: viewModel.currentPageIndex) { _, _ in UISelectionFeedbackGenerator().selectionChanged() }
    }
}

// MARK: - Reusable three-column status row
private struct StatusRowBuilder: View {
    let page: StatusPage
    @State private var rowHeight: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            // Left column
            StatusColumn(primary: page.left.primary, secondary: page.left.secondary, isStatus: page.left.role == .status)
                .frame(maxWidth: .infinity)
                .background(GeometryReader { g in Color.clear.preference(key: RowHeightKey.self, value: g.size.height) })

            Divider().frame(width: 1, height: rowHeight).background(AppTheme.Colors.primaryText50)

            // Center column
            StatusColumn(primary: page.center.primary, secondary: page.center.secondary, isStatus: page.center.role == .status)
                .frame(maxWidth: .infinity)
                .background(GeometryReader { g in Color.clear.preference(key: RowHeightKey.self, value: g.size.height) })

            Divider().frame(width: 1, height: rowHeight).background(AppTheme.Colors.primaryText50)

            // Right column
            StatusColumn(primary: page.right.primary, secondary: page.right.secondary, isStatus: page.right.role == .status)
                .frame(maxWidth: .infinity)
                .background(GeometryReader { g in Color.clear.preference(key: RowHeightKey.self, value: g.size.height) })
        }
        .onPreferenceChange(RowHeightKey.self) { rowHeight = $0 }
    }
}

private struct StatusColumn: View {
    let primary: String
    let secondary: String?
    let isStatus: Bool

    var body: some View {
        VStack(spacing: 6) {
            if isStatus { Spacer(minLength: 0) }
            Text(primary)
                .font(isStatus ? .headline.weight(.bold).monospaced() : .body)
                .foregroundColor(AppTheme.Colors.primaryText)
            if let secondary = secondary {
                Text(secondary)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.primaryText80)
            }
            if isStatus { Spacer(minLength: 0) }
        }
    }
}
