import SwiftUI
import Charts

/// Presents summary analytics as paged cards with an indicator row,
/// reporting its intrinsic size to the surrounding context bar.
struct SummaryView: View {

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout
    @StateObject private var viewModel = SummaryViewModel.shared

    // MARK: - State
    @State private var indicatorHeight: CGFloat = 0
    @State private var indicatorWidth: CGFloat = 0
    @State private var contentHeights: [Int: CGFloat] = [:]

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            pages
                .frame(height: contentHeights[viewModel.currentIndex] ?? 250)
                .padding(.bottom, indicatorHeight + 12)
            indicators
        }
        .onPreferenceChange(Types.SummaryContentHeightKey.self) { contentHeights = $0 }
        .preference(key: DynamicContextBarDesiredHeightKey.self, value: computedDesiredHeight())
        .preference(key: DynamicContextBarDesiredWidthKey.self,  value: computedDesiredWidth())
        .onChange(of: viewModel.currentIndex) { _, _ in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
    }

    // MARK: - Subviews
    private var pages: some View {
        TabView(selection: $viewModel.currentIndex) {
            ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { idx, page in
                SummaryCard(page: page, index: idx)
                    .tag(idx)
                    .contentShape(Rectangle())
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .padding(.bottom, 3)
    }

    private var indicators: some View {
        SummaryPageIndicators(currentIndex: $viewModel.currentIndex, pages: viewModel.pages)
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

    // MARK: - Private Helpers
    private func currentPageHeight() -> CGFloat {
        let idx = viewModel.currentIndex
        let content = contentHeights[idx] ?? 250
        // Content + indicators + spacing
        return content + indicatorHeight + 12
    }

    private func currentPageWidth() -> CGFloat {
        // Expand to almost full screen width (screenWidth - 4)
        // Subtract 40 because DynamicContextBar adds 40pt of internal padding automatically.
        layout.width.value - 4 - 40
    }

    private func computedDesiredHeight() -> CGFloat { currentPageHeight() }
    private func computedDesiredWidth()  -> CGFloat { currentPageWidth() }

    // MARK: - Nested Types (View-only helpers)
    fileprivate enum Types {
        struct SummaryContentHeightKey: PreferenceKey {
            static var defaultValue: [Int: CGFloat] = [:]
            static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
                value.merge(nextValue(), uniquingKeysWith: { $1 })
            }
        }
    }
}

// MARK: - Types
enum SummaryPage: CaseIterable, Identifiable {
    case theSplit, weeklyRitual, dailyRhythm, weekInsights
    var id: Self { self }

    var title: String {
        switch self {
        case .theSplit: return "The Split"
        case .weeklyRitual: return "Weekly Ritual"
        case .dailyRhythm:  return "Daily Rhythm"
        case .weekInsights: return "Week Insights"
        }
    }

    var iconName: String {
        switch self {
        case .theSplit: return "chart.pie"
        case .weeklyRitual: return "chart.bar"
        case .dailyRhythm:  return "sun.horizon"
        case .weekInsights: return "bubbles.and.sparkles"
        }
    }
}

// MARK: - Subview: SummaryCard
struct SummaryCard: View {

    // MARK: - Input
    let page: SummaryPage
    let index: Int

    // MARK: - Environment
    @Environment(\.layout) private var layout
    @ObservedObject private var viewModel = SummaryViewModel.shared

    // MARK: - Body
    var body: some View {
        VStack(spacing: 12) {
            tabHeader
            
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else {
                switch page {
                case .theSplit:
                    theSplit
                case .weeklyRitual:
                    weeklyRitual
                case .dailyRhythm:
                    dailyRhythm
                case .weekInsights:
                    weekInsights
                }
            }
        }
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SummaryView.Types.SummaryContentHeightKey.self, value: [index: g.size.height])
            }
        )
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    // MARK: - Shared Subviews
    private var tabHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: page.iconName)
            Text(page.title)
                .uiText(.title)
                .padding(.vertical, 5) // Prevent font-level clipping
            Spacer()
        }
    }

    private func sectionHeader(_ text: String, _ rawValue: Double, _ isDist: Bool) -> some View {
        HStack {
            Text(text)
                .uiText(.section)
            Spacer()
            changeIndicator(rawValue)
            Text(isDist ? DistanceUtility.formatter(meters: rawValue) : TimeUtility.formatter(rawValue))
                .uiText(.section)
        }
    }

    private func sectionHeader(_ text: String, _ displayValue: String) -> some View {
        HStack {
            Text(text)
                .uiText(.section)
            Spacer()
            Text(displayValue)
                .uiText(.section)
        }
    }

    private func currentTrendsRow(_ value: String) -> some View {
        HStack {
            Text("This Week")
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .uiText(.row)
    }

    private func historicalTrendsRow(_ label: String, _ value: String) -> some View {
        HStack{
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .uiText(.row)
    }

    // MARK: - Pages
    private var weekInsights: some View {
        VStack {
            ScrollView {
                Group {
                    if let d = viewModel.weeklyInsights {
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading) {
                                sectionHeader("Your Busiest Day", d.currentBusiestDOW!)
                                VStack {
                                    historicalTrendsRow("Typically", d.priorBusiestDOW!)
                                }
                            }
                            .uiBlock(.section)

                            VStack(alignment: .leading) {
                                sectionHeader("Average Trip Distance", d.diffDistance!, true)
                                VStack {
                                    currentTrendsRow(d.currentAvgMeters!)
                                    historicalTrendsRow("Typically", d.priorAvgMeters!)
                                }
                            }
                            .uiBlock(.section)

                            VStack(alignment: .leading) {
                                sectionHeader("Average Trip Time", d.diffDuration!, false)
                                VStack {
                                    currentTrendsRow(d.currentAvgDuration!)
                                    historicalTrendsRow("Typically", d.priorAvgDuration!)
                                }
                            }
                            .uiBlock(.section)

                            VStack(alignment: .leading) {
                                sectionHeader("Longest Trip Distance", d.diffLongestTrip!, true)
                                VStack {
                                    currentTrendsRow(d.currentLongestTrip!)
                                    historicalTrendsRow("Longest", d.priorLongestTrip!)
                                }
                            }
                            .uiBlock(.section)

                            VStack(alignment: .leading) {
                                sectionHeader("Longest Trip Time", d.diffLongestDur!, false)
                                VStack {
                                    currentTrendsRow(d.currentLongestDuration!)
                                    historicalTrendsRow("Longest", d.priorLongestDuration!)
                                }
                            }
                            .uiBlock(.section)
                        }
                    }
                }
            }
            .frame(height: layout.height.pct(0.25))
        }
    }

    @ViewBuilder
    private func changeIndicator(_ value: Double) -> some View {
        let size: Font = .system(size: 8)
        if value == 0 {
            Image(systemName: "minus")
                .font(size)
                .foregroundStyle(.gray)
        } else if value > 0 {
            Image(systemName: "triangle.fill")
                .font(size)
                .foregroundStyle(.green)
        } else {
            Image(systemName: "triangle.fill")
                .font(size)
                .rotationEffect(.degrees(180))
                .foregroundStyle(.red)
        }
    }

    private var dailyRhythm: some View {
        VStack(spacing: 6) {
            Group {
                if let hourData = viewModel.hourData {
                    Chart {
                        ForEach(Array(hourData.values.enumerated()), id: \.0) { idx, v in
                            let norm = v / max(hourData.maxValue, 1)
                            let bottom = Color.green
                            let top    = Color(hue: 0.33 * (1 - norm), saturation: 0.95, brightness: 0.95)

                            BarMark(
                                x: .value("Hour", idx),
                                y: .value("Value", v)
                            )
                            .foregroundStyle(
                                LinearGradient(gradient: Gradient(stops: [
                                    .init(color: bottom, location: 0),
                                    .init(color: top,    location: 1),
                                ]), startPoint: .bottom, endPoint: .top)
                            )
                            .cornerRadius(3)
                        }

                        RuleMark(x: .value("6a", 6.0))
                            .lineStyle(.init(lineWidth: 1))
                            .foregroundStyle(.secondary.opacity(0.25))
                            .annotation(position: .bottom, alignment: .center) {
                                Text("6a")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                            }

                        RuleMark(x: .value("12p", 12.0))
                            .lineStyle(.init(lineWidth: 1))
                            .foregroundStyle(.secondary.opacity(0.55))
                            .annotation(position: .bottom, alignment: .center) {
                                Text("12p")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.primary)
                                    .padding(4)
                            }

                        RuleMark(x: .value("6p", 18.0))
                            .lineStyle(.init(lineWidth: 1))
                            .foregroundStyle(.secondary.opacity(0.25))
                            .annotation(position: .bottom, alignment: .center) {
                                Text("6p")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                            }
                    }
                    .chartYScale(domain: 0...(max(hourData.maxValue, 1)))
                    .chartXScale(domain: -0.5...23.5)
                    .chartYAxis(.hidden)
                    .chartXAxis(.hidden)
                    .chartPlotStyle { plot in
                        plot.padding(.bottom, 14)
                    }
                    .frame(height: 160)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }

    private func hourLabel(_ h: Int) -> String {
        switch h {
        case 0: return "12a"
        case 12: return "12p"
        case 1...11: return "\(h)a"
        case 13...23: return "\(h - 12)p"
        default: return ""
        }
    }

    private var weeklyRitual: some View {
        VStack(spacing: 6) {
            Group {
                if let dowData = viewModel.dowData {
                    Chart {
                        ForEach(Array(dowData.meters.enumerated()), id: \.0) { idx, meters in
                            let norm = meters / max(dowData.maxMeters, 1)
                            let bottom = Color.green
                            let top    = hueGreenToRed(norm)

                            BarMark(
                                x: .value("Day", dowData.labels[idx]),
                                y: .value("Meters", meters)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: bottom, location: 0.0),
                                        .init(color: top,    location: 1.0)
                                    ]),
                                    startPoint: .bottom, endPoint: .top
                                )
                            )
                            .cornerRadius(100)
                            .annotation(position: .top, alignment: .center) {
                                if meters > 0 {
                                    Text(dowData.valueTexts[idx])
                                        .uiText(.row)
                                }
                            }
                        }

                        RuleMark(y: .value("Baseline", 0))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: dowData.labels) { _ in
                            AxisValueLabel()
                        }
                    }
                    .chartYScale(domain: 0...(max(dowData.maxMeters, 1)))
                    .frame(height: 140)
                }
            }
            .padding(.top, 24)
        }
    }

    private func hueGreenToRed(_ t: Double) -> Color {
        let clamped = max(0, min(1, t))
        return Color(hue: 0.33 * (1 - clamped), saturation: 0.95, brightness: 0.65)
    }

    private var theSplit: some View {
        VStack(spacing: 6) {
            Group {
                if let breakdownData = viewModel.breakdownData {
                    VStack {
                        PercentRow(
                            percent: breakdownData.milesPercent,
                            percentLabel: breakdownData.milesPercentLabel,
                            rowLabel: breakdownData.milesLabel,
                            rowDescription: breakdownData.milesDescription,
                            color: .green
                        )
                        PercentRow(
                            percent: breakdownData.durationPercent,
                            percentLabel: breakdownData.durationPercentLabel,
                            rowLabel: breakdownData.durationLabel,
                            rowDescription: breakdownData.durationDescription,
                            color: .blue
                        )
                        PercentRow(
                            percent: breakdownData.tripCountPercent,
                            percentLabel: breakdownData.tripCountPercentLabel,
                            rowLabel: breakdownData.tripCountLabel,
                            rowDescription: breakdownData.tripCountDescription,
                            color: .orange
                        )
                    }
                }
            }
        }
    }

    // MARK: - Nested Types
    struct PercentRow: View {
        let percent: Double
        let percentLabel: String
        let rowLabel: String
        let rowDescription: String
        let color: Color

        var body: some View {
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: percent)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(percentLabel)
                        .uiStyle(.info)
                        .lineLimit(1)

                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 8) {
                    Text(rowLabel)
                        .uiText(.section)
                    Text(rowDescription)
                        .uiText(.row)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .uiBlock(.section)
        }
    }
}

// MARK: - Subview: SummaryPageIndicators
struct SummaryPageIndicators: View {

    // MARK: - Input
    @Binding var currentIndex: Int
    let pages: [SummaryPage]

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

fileprivate extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
