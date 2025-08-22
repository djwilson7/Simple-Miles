import SwiftUI
import Foundation
import UIKit
import Combine

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
                    .onLongPressGesture(minimumDuration: 0.4) {
                        if let type = page.tripType {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            viewModel.beginReview(for: type)
                        }
                    }
            }
        }
        .frame(width: layout.width.pct(0.8), height: layout.height.pct(0.2))
        .tabViewStyle(.page(indexDisplayMode: .never))
        .overlay(alignment: .bottom) {
            PageIndicators(
                pages: viewModel.pages,
                current: viewModel.currentPageIndex,
                onSelect: { index in
                    withAnimation(.easeInOut) { viewModel.currentPageIndex = index }
                }
            )
            .padding(.bottom, 8)
        }
        .onChange(of: viewModel.currentPageIndex) { _, _ in UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    }
}

// MARK: - PageIndicators View
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
        case .business:
            return "briefcase"
        case .personal:
            return "car"
        case .custom:
            return "star"
        case .unsorted:
            return "questionmark"
        case .none:
            return "record.circle"
        }
    }

    private func accessibilityLabel(for tripType: TripType?) -> String {
        switch tripType {
        case .business: return "Business"
        case .personal: return "Personal"
        case .custom: return "Custom"
        case .unsorted: return "Unclassified"
        case .none: return "Status"
        }
    }

    private func iconColor(for tripType: TripType?, isCurrent: Bool) -> Color {
        // Status page (nil tripType) reflects live travel state
        if tripType == nil {
            switch travel.state {
            case .traveling:
                return isCurrent ? Color.green : Color.green.opacity(0.6)
            case .paused:
                return isCurrent ? Color.orange : Color.orange.opacity(0.6)
            case .idle:
                // idle: selected white, unselected gray (existing theme semantics)
                return isCurrent ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText50
            }
        }
        // Special case for .unclassified: color depends on trip count
        if tripType == .unsorted {
            let count = unsortedCount
            if count > 0 {
                return isCurrent ? Color.yellow : Color.yellow.opacity(0.6)
            } else {
                return isCurrent ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText50
            }
        }
        // Non-status, non-unclassified pages: keep existing theme
        return isCurrent ? AppTheme.Colors.primaryText : AppTheme.Colors.primaryText50
    }

    private func refreshUnsortedCount() {
        DispatchQueue.global(qos: .userInitiated).async {
            let totals = (try? TripSegmentStore.shared.fetchTotals(type: .unsorted)) ?? .empty
            DispatchQueue.main.async {
                self.unsortedCount = totals.tripCount
            }
        }
    }

    var body: some View {
        GeometryReader { geo in
            let totalWidth = max(geo.size.width, 1)
            HStack(spacing: 16) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    let isCurrent = index == current
                    Image(systemName: iconName(for: page.tripType))
                        .symbolVariant(isCurrent ? .fill : .none)
                        .foregroundColor(iconColor(for: page.tripType, isCurrent: isCurrent))
                        .scaleEffect(isCurrent ? 1.2 : 1.0)
                        .padding(6)
                        .background(
                            Capsule()
                                .fill(isCurrent ? AppTheme.Colors.primaryText.opacity(0.2) : Color.clear)
                        )
                        .animation(.easeInOut(duration: 0.25), value: current)
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
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
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
        .frame(height: 28) // keeps overlay compact while allowing full-width drag hit area
        .onAppear {
            refreshUnsortedCount()
            totalsCancellable = TripSegmentStore.shared.tripTotalsUpdated
                .receive(on: DispatchQueue.main)
                .sink { self.refreshUnsortedCount() }
        }
        .onDisappear { totalsCancellable?.cancel(); totalsCancellable = nil }
    }
}

// MARK: - Reusable three-column status row
private struct StatusRowBuilder: View {
    let page: StatusPage
    @State private var rowHeight: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            // Left column
            StatusColumn(primary: page.left.primary, secondary: page.left.secondary, isStatus: page.left.role == .status, isLiveStatusPage: page.tripType == nil)
                .frame(maxWidth: .infinity)
                .background(GeometryReader { g in Color.clear.preference(key: RowHeightKey.self, value: g.size.height) })

            Divider().frame(width: 1, height: rowHeight).background(AppTheme.Colors.primaryText50)

            // Center column
            StatusColumn(primary: page.center.primary, secondary: page.center.secondary, isStatus: page.center.role == .status, isLiveStatusPage: page.tripType == nil)
                .frame(maxWidth: .infinity)
                .background(GeometryReader { g in Color.clear.preference(key: RowHeightKey.self, value: g.size.height) })

            Divider().frame(width: 1, height: rowHeight).background(AppTheme.Colors.primaryText50)

            // Right column
            StatusColumn(primary: page.right.primary, secondary: page.right.secondary, isStatus: page.right.role == .status, isLiveStatusPage: page.tripType == nil)
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
    let isLiveStatusPage: Bool

    @ObservedObject private var travel = TravelStateManager.shared
    @State private var glowPulse: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private func glowColor() -> Color? {
        switch travel.state {
        case .traveling:
            return Color.green
        case .paused:
            return Color.orange
        case .idle:
            return nil
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
        VStack(spacing: 6) {
            if isStatus { Spacer(minLength: 0) }

            ZStack {
                // Multi-layered glow stack behind the primary text
                if isStatus && isLiveStatusPage, let color = glowColor() {
                    Text(primary)
                        .font(.headline.weight(.bold).monospaced())
                        .foregroundColor(.clear)
                        .overlay(
                            ZStack {
                                // Contrast base for light mode: a soft dark halo to increase readability
                                if colorScheme == .light {
                                    Text(primary)
                                        .foregroundColor(.black)
                                        .blur(radius: 18)
                                        .opacity(0.28)
                                        .blendMode(.multiply)
                                }

                                // Tight inner glow
                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 14)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.98 : 0.78) : 0.90)
                                // Mid glow
                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 28)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.85 : 0.62) : 0.70)
                                // Wide outer glow
                                Text(primary)
                                    .foregroundColor(color)
                                    .blur(radius: 48)
                                    .opacity(travel.state == .traveling ? (glowPulse ? 0.65 : 0.42) : 0.50)
                                // Extra reach halo
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

                // Foreground primary text
                Text(primary)
                    .font(isStatus ? .headline.weight(.bold).monospaced() : .body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    // Subtle extra spread for a nicer glow edge when active
                    .shadow(color: ((isStatus && isLiveStatusPage) ? glowColor()?.opacity(travel.state == .traveling ? (glowPulse ? 0.85 : 0.55) : 0.65) : nil) ?? .clear, radius: 12)
                    .shadow(color: ((isStatus && isLiveStatusPage) ? glowColor()?.opacity(travel.state == .traveling ? (glowPulse ? 0.55 : 0.32) : 0.40) : nil) ?? .clear, radius: 22)
                    .shadow(color: ((isStatus && isLiveStatusPage) ? glowColor()?.opacity(travel.state == .traveling ? (glowPulse ? 0.28 : 0.18) : 0.22) : nil) ?? .clear, radius: 36)
            }

            if let secondary = secondary {
                Text(secondary)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.primaryText80)
            }
            if isStatus { Spacer(minLength: 0) }
        }
        // Drive pulse animation only in traveling state
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
