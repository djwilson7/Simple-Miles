import SwiftUI
import Foundation
import UIKit
import Combine

/// Displays live trip status and category totals as paged rows with indicators.
/// Sizes itself via preferences to inform the surrounding context bar layout.
struct SnapshotView: View {

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout
    @ObservedObject var viewModel = SnapshotViewModel.shared

    // MARK: - State
    @State private var pageWidths: [Int: CGFloat] = [:]

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            pages
            pageIndicators
        }
        .onPreferenceChange(Types.PageWidthKey.self) { pageWidths = $0 }
        .onChange(of: viewModel.currentPageIndex) { _, _ in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        .preference(key: DynamicContextBarDesiredHeightKey.self, value: computedDesiredHeight())
        .preference(key: DynamicContextBarDesiredWidthKey.self, value: computedDesiredWidth())
    }

    // MARK: - Subviews
    private var pages: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { index, page in
                StatusRowBuilder(page: page, index: index)
                    .tag(index)
                    .background(
                        GeometryReader { g in
                            Color.clear
                                .preference(key: Types.PageWidthKey.self, value: [index: g.size.width])
                        }
                    )
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(height: 60) // Stable height for the status rows
    }

    private var pageIndicators: some View {
        PageIndicators(
            pages: viewModel.pages,
            current: viewModel.currentPageIndex,
            onSelect: { index in
                viewModel.currentPageIndex = index
            }
        )
    }

    // MARK: - Private Helpers
    private func computedDesiredHeight() -> CGFloat {
        // 60 (pages) + 50 (indicators) + 5 (buffer)
        return 115
    }

    private func currentPageWidth() -> CGFloat {
        pageWidths[viewModel.currentPageIndex] ?? layout.width.pct(0.8)
    }

    private func computedDesiredWidth() -> CGFloat {
        // Match the visual width of the title bar (which is screenWidth - 2 * horizontalEdgeInset)
        // Subtract 40 because DynamicContextBar adds 40pt of internal padding automatically.
        return layout.width.value - (layout.horizontalEdgeInset * 2) - 40
    }

    // MARK: - Nested Types (View-only helpers)
    enum Types {
        struct PageIntrinsicRowHeightKey: PreferenceKey {
            static var defaultValue: [Int: CGFloat] = [:]
            static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
                value.merge(nextValue(), uniquingKeysWith: { $1 })
            }
        }

        struct PageWidthKey: PreferenceKey {
            static var defaultValue: [Int: CGFloat] = [:]
            static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
                value.merge(nextValue(), uniquingKeysWith: { $1 })
            }
        }
    }
}

// MARK: - Subview: PageIndicators
private struct PageIndicators: View {
    let pages: [StatusPage]
    let current: Int
    var onSelect: (Int) -> Void = { _ in }

    @State private var lastHapticIndex: Int? = nil
    @ObservedObject private var travel = TravelStateManager.shared

    @State private var unsortedCount: Int = 0
    @State private var totalsCancellable: AnyCancellable? = nil

    private var liveStatusIndex: Int? {
        pages.firstIndex(where: { $0.tripType == nil })
    }

    private func iconName(for tripType: TripType?) -> String {
        switch tripType {
        case .business: return "briefcase"
        case .personal: return "car"
        case .custom: return "star"
        case .unsorted: return "questionmark"
        case .trash: return "trash"
        case .none: return "waveform.circle"
        }
    }

    private func accessibilityLabel(for tripType: TripType?) -> String {
        switch tripType {
        case .business: return "Business"
        case .personal: return "Personal"
        case .custom: return "Custom"
        case .unsorted: return "Unsorted"
        case .trash: return "Trash"
        case .none: return "Status"
        }
    }

    private func iconColor(for tripType: TripType?, isCurrent: Bool) -> Color {
        if tripType == nil {
            switch travel.state {
            case .traveling:
                return isCurrent ? Color.green : Color.green.opacity(0.6)
            case .paused:
                return isCurrent ? Color.orange : Color.orange.opacity(0.6)
            case .idle:
                return isCurrent ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText50
            }
        }
        if tripType == .unsorted {
            let count = unsortedCount
            if count > 0 {
                return isCurrent ? Color.yellow : Color.yellow.opacity(0.6)
            } else {
                return isCurrent ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText50
            }
        }
        return isCurrent ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText50
    }

    private func refreshUnsortedCount() {
        DispatchQueue.global(qos: .userInitiated).async {
            let totals = (try? SegmentStore.shared.fetchTotals(type: .unsorted)) ?? .empty
            DispatchQueue.main.async {
                self.unsortedCount = totals.tripCount
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let totalWidth = max(geo.size.width, 1)
            HStack {
                Spacer()
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    let isCurrent = index == current
                    Spacer()
                    Image(systemName: iconName(for: page.tripType))
                        .uiText(.title)
                        .symbolVariant(isCurrent ? .fill : .none)
                        .foregroundColor(iconColor(for: page.tripType, isCurrent: isCurrent))
                        .scaleEffect(isCurrent ? 1.5 : 1.0)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if index == current, let statusIdx = liveStatusIndex, statusIdx != current {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                onSelect(statusIdx)
                            } else {
                                onSelect(index)
                            }
                        }
                        .accessibilityAddTraits(isCurrent ? .isSelected : [])
                        .accessibilityLabel(accessibilityLabel(for: page.tripType))
                    Spacer()
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .uiBlock(.title)
            .gesture(
                DragGesture(minimumDistance: 3, coordinateSpace: .local)
                    .onChanged { value in
                        let count = max(pages.count, 1)
                        let slot = totalWidth / CGFloat(count)
                        let clampedX = min(max(value.location.x, 0), totalWidth - 0.001)
                        let idx = Int(clampedX / slot)
                        if idx != lastHapticIndex {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            lastHapticIndex = idx
                        }
                        if idx != current { onSelect(idx) }
                    }
                    .onEnded { value in
                        let count = max(pages.count, 1)
                        let slot = totalWidth / CGFloat(count)
                        let clampedX = min(max(value.location.x, 0), totalWidth - 0.001)
                        let idx = Int(clampedX / slot)
                        if idx != current { onSelect(idx) }
                        lastHapticIndex = nil
                    }
            )
        }
        .frame(height: 50)
        .onAppear {
            refreshUnsortedCount()
            totalsCancellable = SegmentStore.shared.tripTotalsUpdated
                .receive(on: DispatchQueue.main)
                .sink { self.refreshUnsortedCount() }
        }
        .onDisappear { totalsCancellable?.cancel(); totalsCancellable = nil }
    }
}

// MARK: - Subview: StatusRowBuilder
private struct StatusRowBuilder: View {
    let page: StatusPage
    let index: Int

    var body: some View {
        HStack(spacing: 0) {
            StatusColumn(
                primary: page.left.primary,
                secondary: page.left.secondary,
                isStatus: page.left.role == .status,
                isLiveStatusPage: page.tripType == nil
            )
            .frame(maxWidth: .infinity)

            Divider()
                .frame(width: 1, height: 32)
                .background(AppTheme.Colors.primaryText50)

            StatusColumn(
                primary: page.center.primary,
                secondary: page.center.secondary,
                isStatus: page.center.role == .status,
                isLiveStatusPage: page.tripType == nil
            )
            .frame(maxWidth: .infinity)

            Divider()
                .frame(width: 1, height: 32)
                .background(AppTheme.Colors.primaryText50)

            StatusColumn(
                primary: page.right.primary,
                secondary: page.right.secondary,
                isStatus: page.right.role == .status,
                isLiveStatusPage: page.tripType == nil
            )
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Subview: StatusColumn
private struct StatusColumn: View {
    let primary: String
    let secondary: String?
    let isStatus: Bool
    let isLiveStatusPage: Bool

    @ObservedObject private var travel = TravelStateManager.shared
    @State private var glowPulse: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private func glowColor() -> Color? {
        switch travel.state {
        case .traveling: return Color.green
        case .paused: return Color.orange
        case .idle: return nil
        }
    }

    private func secondsToNextTick() -> Double {
        let now = Date().timeIntervalSince1970
        let frac = now - floor(now)
        return max(0.0, 1.0 - frac)
    }

    private func startPulseSynced() {
        let delay = secondsToNextTick()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                glowPulse.toggle()
            }
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            if isStatus { Spacer(minLength: 0) }

            ZStack {
                if isStatus && isLiveStatusPage, let color = glowColor() {
                    Text(primary)
                        .font(.headline.weight(.bold).monospaced())
                        .foregroundColor(.clear)
                        .overlay(
                            ZStack {
                                if colorScheme == .light {
                                    Text(primary)
                                        .foregroundColor(.black)
                                        .blur(radius: 18)
                                        .opacity(0.28)
                                        .blendMode(.multiply)
                                }

                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 14)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.98 : 0.78) : 0.90)
                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 28)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.85 : 0.62) : 0.70)
                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 48)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.65 : 0.42) : 0.50)
                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 72)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.45 : 0.28) : 0.35)
                            }
                            .scaleEffect(travel.state == .traveling ? (glowPulse ? 1.08 : 1.0) : 1.0)
                            .blendMode(.plusLighter)
                            .compositingGroup()
                        )
                }

                Text(primary)
                    .font(isStatus ? .headline.weight(.bold).monospaced() : .body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .shadow(color: ((isStatus && isLiveStatusPage) ? glowColor()?.opacity(travel.state == .traveling ? (glowPulse ? 0.85 : 0.55) : 0.65) : nil) ?? .clear, radius: 12)
                    .shadow(color: ((isStatus && isLiveStatusPage) ? glowColor()?.opacity(travel.state == .traveling ? (glowPulse ? 0.55 : 0.32) : 0.40) : nil) ?? .clear, radius: 22)
                    .shadow(color: ((isStatus && isLiveStatusPage) ? glowColor()?.opacity(travel.state == .traveling ? (glowPulse ? 0.28 : 0.18) : 0.22) : nil) ?? .clear, radius: 36)
            }

            Text(secondary ?? " ")
                .font(.caption)
                .foregroundColor(AppTheme.Colors.primaryText80)
                .opacity(secondary == nil ? 0 : 1)
                .lineLimit(1)

            if isStatus { Spacer(minLength: 0) }
        }
        .onAppear {
            if isStatus && isLiveStatusPage && travel.state == .traveling {
                glowPulse = false
                startPulseSynced()
            }
        }
        .onChange(of: travel.state) { _, newValue in
            if isStatus && isLiveStatusPage {
                if newValue == .traveling {
                    glowPulse = false
                    startPulseSynced()
                } else {
                    glowPulse = false
                }
            }
        }
    }
}
