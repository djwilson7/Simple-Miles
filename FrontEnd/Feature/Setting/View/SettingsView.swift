import SwiftUI

/// Presents the Settings screens as paged cards with indicators and dynamic sizing
/// for the surrounding context bar.
struct SettingsView: View {

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout
    @StateObject private var viewModel = SettingsViewModel.shared

    // MARK: - State
    @State private var indicatorHeight: CGFloat = 0
    @State private var indicatorWidth: CGFloat = 0
    @State private var contentHeights: [Int: CGFloat] = [:]
    @State private var contentWidths: [Int: CGFloat] = [:]

    // MARK: - Body
    var body: some View {
        VStack {
            pages
            indicators
        }
        .frame(
            width: min(layout.width.pct(0.95), layout.height.pct(0.95)),
        )
        .onPreferenceChange(Types.SettingsPageHeightKey.self) { contentHeights = $0 }
        .onPreferenceChange(Types.SettingsPageWidthKey.self) { contentWidths = $0 }
        .preference(
            key: DynamicContextBarDesiredHeightKey.self,
            value: computedDesiredHeight()
        )
        .preference(
            key: DynamicContextBarDesiredWidthKey.self,
            value: computedDesiredWidth()
        )
        .onChange(of: viewModel.currentIndex) { _, _ in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    // MARK: - Subviews
    private var pages: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { idx, page in
                SettingCard(page: page, index: idx)
                    .tag(idx)
                    .contentShape(Rectangle())
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.bottom, 3)
    }

    private var indicators: some View {
        SettingPageIndicators(
            currentIndex: $viewModel.currentIndex,
            pages: viewModel.pages
        )
        .padding(.bottom, 3)
        .background(
            GeometryReader { g in
                Color.clear
                    .onAppear {
                        indicatorHeight = g.size.height
                        indicatorWidth = g.size.width
                    }
                    .onChange(of: g.size.height) { _, h in
                        indicatorHeight = h
                    }
                    .onChange(of: g.size.width) { _, w in
                        indicatorWidth = w
                    }
            }
        )
    }

    // MARK: - Private Helpers
    private func currentPageHeight() -> CGFloat {
        let idx = viewModel.currentIndex
        let content = contentHeights[idx] ?? 200
        return content + indicatorHeight + 3
    }

    private func currentPageWidth() -> CGFloat {
        let idx = viewModel.currentIndex
        return contentWidths[idx] ?? layout.width.pct(0.8)
    }

    private func computedDesiredHeight() -> CGFloat { currentPageHeight() }
    private func computedDesiredWidth() -> CGFloat { currentPageWidth() }

    // MARK: - Nested Types (View-only helpers)
    fileprivate enum Types {
        struct SettingsPageHeightKey: PreferenceKey {
            static var defaultValue: [Int: CGFloat] = [:]
            static func reduce(
                value: inout [Int: CGFloat],
                nextValue: () -> [Int: CGFloat]
            ) {
                value.merge(nextValue(), uniquingKeysWith: { $1 })
            }
        }

        struct SettingsPageWidthKey: PreferenceKey {
            static var defaultValue: [Int: CGFloat] = [:]
            static func reduce(
                value: inout [Int: CGFloat],
                nextValue: () -> [Int: CGFloat]
            ) {
                value.merge(nextValue(), uniquingKeysWith: { $1 })
            }
        }
    }
}

// MARK: - Types
enum SettingsPage: CaseIterable, Identifiable {
    case account, display, tracking
    var id: Self { self }

    var title: String {
        switch self {
        case .account: return "Account"
        case .display: return "Display"
        case .tracking: return "Tracking"
        }
    }

    var iconName: String {
        switch self {
        case .account: return "person.crop.circle"
        case .display: return "paintpalette"
        case .tracking: return "dot.radiowaves.left.and.right"
        }
    }
}

// MARK: - Subview: SettingCard
struct SettingCard: View {

    // MARK: - Input
    let page: SettingsPage
    let index: Int

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout
    @StateObject private var settings = SettingsManager.shared

    // MARK: - Body
    var body: some View {
        switch page {
        case .account:
            accountPage
        case .display:
            displayPage
        case .tracking:
            trackingPage
        }
    }

    // MARK: - Subviews (Shared)
    private var tabHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: page.iconName)
            Text(page.title)
                .uiText(.title)
            Spacer()
        }
        .uiBlock(.title)
    }

    private func sectionHeader(_ label: String) -> some View {
        HStack {
            Text(label)
            Spacer()
        }
        .uiStyle(.title)
    }

    // MARK: - Subviews (Pages)
    private var accountPage: some View {
        VStack {
            tabHeader
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
        .background(sizeReportingBackground)
    }

    private var displayPage: some View {
        VStack {
            tabHeader
            themeOverrideSetting.uiBlock(.title)
            materialOverrideSetting.uiBlock(.title)
            accentColorSetting.uiBlock(.title)
        }
        .padding(16)
        .background(sizeReportingBackground)
    }

    private var trackingPage: some View {
        VStack {
            tabHeader
            pauseTimerSetting.uiBlock(.title)
            minimumTripDistanceSetting.uiBlock(.title)
            distanceSetting.uiBlock(.title)
        }
        .padding(16)
        .background(sizeReportingBackground)
    }

    // MARK: - Subviews (Settings Controls)
    private var themeOverrideSetting: some View {
        VStack {
            HStack {
                Text("System Theme")
                    .uiText(.section)
                Spacer()
            }
            SegmentedPicker(selection: $settings.themeOverride)
        }
    }

    private var materialOverrideSetting: some View {
        VStack {
            HStack {
                Text("Material")
                    .uiText(.section)
                Spacer()
            }
            SegmentedPicker(selection: $settings.materialOverride)
        }
    }

    private var accentColorSetting: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Layout Color")
                .uiText(.section)

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Hue")
                        .uiText(.row)
                        .foregroundStyle(.secondary)
                        .gridCellAnchor(.leading)
                    GradientTrackSlider(
                        value: $settings.primaryHue,
                        range: 0...1,
                        gradient: hueGradient()
                    )
                    .accessibilityLabel("Hue")
                }
                GridRow {
                    Text("Saturation")
                        .uiText(.row)
                        .foregroundStyle(.secondary)
                        .gridCellAnchor(.leading)
                    GradientTrackSlider(
                        value: $settings.saturation,
                        range: 0...1,
                        gradient: saturationGradient(
                            h: settings.primaryHue,
                            b: settings.brightness
                        )
                    )
                    .accessibilityLabel("Saturation")
                }
                GridRow {
                    Text("Brightness")
                        .uiText(.row)
                        .foregroundStyle(.secondary)
                        .gridCellAnchor(.leading)
                    GradientTrackSlider(
                        value: $settings.brightness,
                        range: 0...1,
                        gradient: brightnessGradient(
                            h: settings.primaryHue,
                            s: settings.saturation
                        )
                    )
                    .accessibilityLabel("Brightness")
                }
            }
        }
    }

    private var distanceSetting: some View {
        VStack {
            HStack {
                Text("Distance Unit")
                    .uiText(.section)
                Spacer()
            }
            SegmentedPicker(selection: $settings.distanceUnit)
        }
    }

    private var minimumTripDistanceSetting: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Ignore trips shorter than")
                        .lineLimit(1)
                        .uiText(.section)
                    Text("In Meters: \(String(format: "%.1f", settings.minDistanceMeters))")
                        .uiText(.row)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(
                    String(
                        format: "%.1f\(settings.distanceUnit.abb)",
                        settings.minimumTripDistance
                    )
                )
                .uiText(.section)
                Stepper(
                    "",
                    value: $settings.minimumTripDistance,
                    in: 0.1...3.0,
                    step: 0.1
                )
                .labelsHidden()
                .frame(alignment: .trailing)
            }
        }
    }

    private var pauseTimerSetting: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Paused Timer")
                        .lineLimit(1)
                        .uiText(.section)
                    Text("End trip if paused this long")
                        .uiText(.row)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(TimeUtility.formatter(settings.pauseTimer))
                    .uiText(.section)
                Stepper(
                    "",
                    value: $settings.pauseTimer,
                    in: 30...600,
                    step: 030
                )
                .labelsHidden()
                .frame(alignment: .trailing)
            }
        }
    }

    // MARK: - Helpers
    private var sizeReportingBackground: some View {
        GeometryReader { g in
            Color.clear
                .preference(
                    key: SettingsView.Types.SettingsPageHeightKey.self,
                    value: [index: g.size.height]
                )
                .background(Color.clear.preference(
                    key: SettingsView.Types.SettingsPageWidthKey.self,
                    value: [index: g.size.width]
                ))
        }
    }
}

// MARK: - Subview: SettingPageIndicators
struct SettingPageIndicators: View {

    // MARK: - Input
    @Binding var currentIndex: Int
    let pages: [SettingsPage]

    // MARK: - Environment
    @Environment(\.layout) private var layout

    // MARK: - Body
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
