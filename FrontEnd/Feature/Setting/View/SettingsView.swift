import SwiftUI
import CoreLocation

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
        ZStack(alignment: .bottom) {
            pages
                .frame(height: contentHeights[viewModel.currentIndex] ?? 250)
                .padding(.bottom, indicatorHeight + 12)
            indicators
                
        }
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
        let content = contentHeights[idx] ?? 250
        // content + indicators + spacing
        return content + indicatorHeight + 12
    }

    private func currentPageWidth() -> CGFloat {
        // Expand to almost full screen width (screenWidth - 4)
        // Subtract 40 because DynamicContextBar adds 40pt of internal padding automatically.
        layout.width.value - 4 - 40
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
    case data, display, tracking
    var id: Self { self }

    var title: String {
        switch self {
        case .data: return "Data"
        case .display: return "Appearance"
        case .tracking: return "Tracking"
        }
    }

    var iconName: String {
        switch self {
        case .data: return "externaldrive"
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
    @ObservedObject private var viewModel = SettingsViewModel.shared

    // MARK: - State
    @State private var showEraseAlert = false
    @State private var showNoTripsAlert = false
    @State private var csvURL: URL? = nil

    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            tabHeader
            
            Group {
                switch page {
                case .data:
                    dataPage
                case .display:
                    displayPage
                case .tracking:
                    trackingPage
                }
            }
        }
        .background(sizeReportingBackground)
        .alert("Erase All Data?", isPresented: $showEraseAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Erase Everything", role: .destructive) {
                SettingsManager.shared.eraseAllData()
            }
        } message: {
            Text("This will permanently delete all trip history and settings. This action cannot be undone.")
        }
        .alert("No Data Found", isPresented: $showNoTripsAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("You haven't recorded any trips yet. Record or classify a trip before exporting.")
        }
        .onAppear {
            csvURL = SettingsManager.shared.exportCSV()
        }
    }

    // MARK: - Subviews (Shared)
    private var tabHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: page.iconName)
            Text(page.title)
                .font(.title3.weight(.semibold).monospaced())
                .padding(.vertical, 5) // Prevent font-level clipping
            Spacer()
        }
    }
    
    // MARK: - Private Helpers
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var locationStatusText: String {
        let status = CLLocationManager().authorizationStatus
        switch status {
        case .authorizedAlways: return "Always Granted"
        case .authorizedWhenInUse: return "While In Use"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private func SettingHeader(_ title: String,_ desc: String) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline.bold())
            Text(desc)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Subviews (Pages)
    private var dataPage: some View {
        VStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Data Management
                    VStack(alignment: .leading) {
                        SettingHeader("Trip History", "Manage your recorded data")
                        HStack(spacing: 12) {
                            if let url = csvURL {
                                ShareLink(item: url) {
                                    Label("Export CSV", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.primary)
                            } else {
                                Button {
                                    showNoTripsAlert = true
                                } label: {
                                    Label("Export CSV", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .tint(.primary)
                            }
                            
                            Button(role: .destructive) {
                                showEraseAlert = true
                            } label: {
                                Label("Erase All", systemImage: "trash")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.top, 8)
                    }
                    .uiBlock(.section)

                    // System Permissions
                    VStack(alignment: .leading) {
                        SettingHeader("Permissions", "Location access status")
                        HStack {
                            Text(locationStatusText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .uiBlock(.section)

                    // About
                    VStack(alignment: .leading) {
                        SettingHeader("About Simple Miles", "Version & Legal")
                        HStack {
                            Text("Version")
                            Spacer()
                            Text(appVersion)
                                .foregroundColor(.secondary)
                        }
                        .uiBlock(.row)
                        
                        Link(destination: URL(string: "https://simplemiles.app/privacy")!) {
                            HStack {
                                Text("Privacy Policy")
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                            }
                        }
                        .uiBlock(.row)
                    }
                    .uiBlock(.section)
                }
            }
            .frame(height: layout.height.pct(0.25))
        }
    }

    private var displayPage: some View {
        VStack {
            themeOverrideSetting.uiBlock(.section)
            materialOverrideSetting.uiBlock(.section)
            accentColorSetting.uiBlock(.section)
        }
    }

    private var trackingPage: some View {
        VStack {
            pauseTimerSetting.uiBlock(.section)
            minimumTripDistanceSetting.uiBlock(.section)
            distanceSetting.uiBlock(.section)
        }
    }

    // MARK: - Subviews (Settings Controls)
    private var themeOverrideSetting: some View {
        HStack {
            SettingHeader("Appearance", "Light vs Dark")
            Spacer()
            MenuPicker(selection: $settings.themeOverride)
        }
    }

    private var materialOverrideSetting: some View {
        HStack {
            SettingHeader("Style", "Set background preference")
            Spacer()
            MenuPicker(selection: $settings.materialOverride)
        }
    }

    private var accentColorSetting: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingHeader("Layout Color", "Personalized tint preference")

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                GridRow {
                    Text("Hue")
                        .font(.caption)
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
                        .font(.caption)
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
                        .font(.caption)
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
        HStack {
            SettingHeader("Distance Unit", "Set your base unit")
            Spacer()
            MenuPicker(selection: $settings.distanceUnit)
        }
    }

    // Replace Stepper with a MenuPicker bound to 0.1...1.5 in 0.1 steps (current unit).
    private var minimumTripDistanceSetting: some View {
        HStack {
            SettingHeader("Minimum Distance", "Ignore trips shorter than:")
            Spacer()
            MenuPicker(selection: minDistanceBinding)
        }
    }

    // Replaces the Stepper with a MenuPicker bound to 30s...600s in 30s steps.
    private var pauseTimerSetting: some View {
        HStack {
            SettingHeader("Paused Timer", "End trip if paused:")
            Spacer()
            MenuPicker(selection: pauseTimerBinding)
        }
    }

    // Binding that maps SettingsManager.pauseTimer (seconds) <-> PauseTimerChoice (exact/closest match)
    private var pauseTimerBinding: Binding<PauseTimerChoice> {
        Binding<PauseTimerChoice>(
            get: {
                PauseTimerChoice.closest(to: settings.pauseTimer)
            },
            set: { choice in
                settings.pauseTimer = choice.seconds
            }
        )
    }

    // Binding that maps SettingsManager.minimumTripDistance (unit value) <-> MinDistanceChoice (unit value)
    private var minDistanceBinding: Binding<MinDistanceChoice> {
        Binding<MinDistanceChoice>(
            get: {
                MinDistanceChoice.exactUnit(settings.minimumTripDistance)
            },
            set: { choice in
                // Store directly as the unit value (0.1...1.5)
                settings.minimumTripDistance = choice.unitValue
            }
        )
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

// MARK: - Local Types (file-scope for stable identity)
struct PauseTimerChoice: SegmentedPickerOption {
    let seconds: Double
    var id: Double { seconds }

    var displayName: String {
        TimeUtility.formatter(seconds)
    }

    // Constant, stable list (30s through 600s stepping by 30s)
    static let allCases: [PauseTimerChoice] =
        stride(from: 30, through: 300, by: 30).map { PauseTimerChoice(seconds: Double($0)) }

    // Find the exact match or the nearest option if not exact.
    static func closest(to seconds: Double) -> PauseTimerChoice {
        if let exact = allCases.first(where: { $0.seconds == seconds }) {
            return exact
        }
        return allCases.min(by: { abs($0.seconds - seconds) < abs($1.seconds - seconds) }) ?? PauseTimerChoice(seconds: 30)
    }
}

@MainActor
struct MinDistanceChoice: @MainActor SegmentedPickerOption, @MainActor Identifiable, @MainActor CaseIterable {
    // Value in the currently selected unit (miles or kilometers)
    let unitValue: Double
    var id: Double { unitValue }

    // Always display with the current unit abbreviation
    var displayName: String {
        let abb = SettingsManager.shared.distanceUnit.abb
        return String(format: "%.1f%@", unitValue, abb)
    }

    // Constant, stable list (0.1 through 1.5 stepping by 0.1) in unit values
    static let allCases: [MinDistanceChoice] = {
        var arr: [MinDistanceChoice] = []
        var v: Double = 0.1
        while v <= 1.001 {
            let rounded = (v * 10).rounded() / 10.0
            arr.append(MinDistanceChoice(unitValue: rounded))
            v += 0.1
        }
        return arr
    }()

    // Exact mapping: find the item whose unitValue exactly equals the stored unit value; if not found, fallback.
    static func exactUnit(_ value: Double) -> MinDistanceChoice {
        if let match = allCases.first(where: { abs($0.unitValue - value) < 0.0001 }) {
            return match
        }
        return allCases.first ?? MinDistanceChoice(unitValue: 0.1)
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

