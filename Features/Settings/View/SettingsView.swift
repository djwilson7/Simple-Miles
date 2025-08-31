import SwiftUI

/// Collect measured heights per page so we can forward the current page's height to the dynamic context bar
private struct SettingsPageHeightKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct SettingsPageWidthKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}


struct SettingsView: View {
    @Environment(\.layout) private var layout
    @StateObject private var viewModel = SettingsViewModel.shared
    @State private var indicatorHeight: CGFloat = 0
    @State private var indicatorWidth: CGFloat = 0
    @State private var contentHeights: [Int: CGFloat] = [:]
    @State private var contentWidths: [Int: CGFloat] = [:]
    

    var body: some View {
        VStack {
            // Pager
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { idx, page in
                    SettingCard(page: page, index: idx)
                        .tag(idx)
                        .contentShape(Rectangle())
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.bottom, 3)
            
            // Page Indicators (tap to switch, matches Status pager UX)
            SettingPageIndicators(currentIndex: $viewModel.currentIndex, pages: viewModel.pages)
                .padding(.bottom, 3)
                .background(
                    GeometryReader { g in
                        Color.clear
                            .onAppear {
                                indicatorHeight = g.size.height
                                indicatorWidth = g.size.width
                            }
                            .onChange(of: g.size.height) { _, h in indicatorHeight = h }
                            .onChange(of: g.size.width) { _, w in indicatorWidth = w }
                    }
                )
        }
        .onPreferenceChange(SettingsPageHeightKey.self) { contentHeights = $0 }
        .onPreferenceChange(SettingsPageWidthKey.self) { contentWidths = $0 }
        .preference(key: DynamicContextBarDesiredHeightKey.self, value: computedDesiredHeight())
        .preference(key: DynamicContextBarDesiredWidthKey.self,  value: computedDesiredWidth())
        .onChange(of: viewModel.currentIndex) { _, _ in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }
    
    private func currentPageHeight() -> CGFloat {
        let idx = viewModel.currentIndex
        let content = contentHeights[idx] ?? 200 // safe fallback
        return content + indicatorHeight + 3
    }
    
    private func currentPageWidth() -> CGFloat {
        let idx = viewModel.currentIndex
        return contentWidths[idx] ?? layout.width.pct(0.8) // safe fallback
    }
    
    private func computedDesiredHeight() -> CGFloat { currentPageHeight() }
    private func computedDesiredWidth()  -> CGFloat { currentPageWidth() }
}

enum SettingsPage: CaseIterable, Identifiable {
    case account, display, tracking
    var id: Self { self }
    var title: String {
        switch self {
        case .account:  return "Account"
        case .display:  return "Display"
        case .tracking: return "Tracking"
        }
    }
    var iconName: String {
        switch self {
        case .account:  return "person.crop.circle"
        case .display:  return "paintpalette"
        case .tracking: return "dot.radiowaves.left.and.right"
        }
    }
}

struct SettingCard: View {
    let page: SettingsPage
    let index: Int
    @Environment(\.layout) private var layout
    @StateObject private var settings = SettingsCenter.shared

    var body: some View {
        switch page {
        case .account:
            AccountPage
        case .display:
            DisplayPage
        case .tracking:
            TrackingPage
        }
    }
    
    private var TabHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: page.iconName)
            Text(page.title)
                .uiText(.title)
            Spacer()
        }
        .uiBlock(.title)
    }
    
    private var AccountPage: some View {
        VStack {
            TabHeader
            ScrollView {
                Group {
                    HStack {
                        Text("Left")
                        Spacer()
                        Text("Right")
                    }
                    .uiBlock(.row)
                    
                }
            }
            .frame(height: layout.height.pct(0.25))
        }
        .padding(16)
        .frame(width: layout.width.pct(0.95))
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SettingsPageHeightKey.self, value: [index: g.size.height])
                Color.clear.preference(key: SettingsPageWidthKey.self, value: [index: g.size.width])
            }
        )
    }
    
    private var DisplayPage: some View {
        VStack {
            TabHeader
            ScrollView {
                Group {
                    HStack {
                        distanceSetting
                    }
                    .uiBlock(.row)
                    
                }
            }
            .frame(height: layout.height.pct(0.25))
        }
        .padding(16)
        .frame(width: layout.width.pct(0.95))
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SettingsPageHeightKey.self, value: [index: g.size.height])
                Color.clear.preference(key: SettingsPageWidthKey.self, value: [index: g.size.width])
            }
        )
    }
    
    private var distanceSetting: some View {
        VStack {
            HStack {
                Text("Distance Unit")
                Spacer()
                Picker("", selection: $settings.distanceUnit) {
                    ForEach(DistanceUnit.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private var TrackingPage: some View {
        VStack {
            TabHeader
            ScrollView {
                Group {
                    HStack {
                        minimumTripDistance
                    }
                    .uiBlock(.row)
                    
                }
            }
            .frame(height: layout.height.pct(0.25))
        }
        .padding(16)
        .frame(width: layout.width.pct(0.95))
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SettingsPageHeightKey.self, value: [index: g.size.height])
                Color.clear.preference(key: SettingsPageWidthKey.self, value: [index: g.size.width])
            }
        )
    }
    
    private var minimumTripDistance: some View {
        VStack {
            HStack {
                Text("Minimum Trip Distance:")
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.1f\(settings.distanceUnit.abb)", settings.minimumTripDistance))
                Stepper(
                    "",
                    value: $settings.minimumTripDistance,
                    in: 0.1...3.0,
                    step: 0.1
                )
                .labelsHidden()
                .frame(alignment: .trailing)
            }
            
            HStack {
                Text("Paused Timer:")
                    .lineLimit(1)
                Spacer()
                Text(TimeUtility.formatter(settings.pauseTimer))
                Stepper(
                    "",
                    value: $settings.pauseTimer,
                    in: 30...600,
                    step: 30
                )
                .labelsHidden()
                .frame(alignment: .trailing)
            }
        }
    }
}

// MARK: - Indicators (tap to jump)
struct SettingPageIndicators: View {
    @Binding var currentIndex: Int
    let pages: [SettingsPage]
    @Environment(\.layout) private var layout
    
    var body: some View {
        HStack(spacing: 30) {
            Spacer()
            ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                let isCurrent = (idx == currentIndex)
                
                Image(systemName: page.iconName)
                    .symbolVariant(isCurrent ? .fill : .none)
                    .uiText(.title)
                    .foregroundStyle(isCurrent ? .primary : .secondary)
                    .scaleEffect(isCurrent ? 1.5 : 1.0)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard currentIndex != idx else { return }
                        currentIndex = idx
                    }
                    .accessibilityLabel(Text(page.title))
                    .accessibilityAddTraits(isCurrent ? .isSelected : [])
            }
            Spacer()
        }
        .uiBlock(.section)
    }
}
