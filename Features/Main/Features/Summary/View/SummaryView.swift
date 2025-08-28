import SwiftUI
import Charts

private struct SummaryContentHeightKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Summary View (Pager inside the Dynamic Context Bar region)
struct SummaryView: View {
    @Environment(\.layout) private var layout
    @StateObject private var viewModel = SummaryViewModel.shared
    @State private var indicatorHeight: CGFloat = 0
    @State private var indicatorWidth: CGFloat = 0
    @State private var contentHeights: [Int: CGFloat] = [:]

    var body: some View {
        VStack {
            // Pager
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.pages.enumerated()), id: \.offset) { idx, page in
                    SummaryCard(page: page, index: idx)
                        .tag(idx)
                        .contentShape(Rectangle())
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.bottom, 3)

            // Page Indicators (tap to switch, matches Status pager UX)
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
        .onPreferenceChange(SummaryContentHeightKey.self) { contentHeights = $0 }
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
        // Keep the standard content width, ensure indicators fit.
        let contentWidth = layout.width.pct(0.8)
        return max(contentWidth, indicatorWidth)
    }
    
    private func computedDesiredHeight() -> CGFloat { currentPageHeight() }
    private func computedDesiredWidth()  -> CGFloat { currentPageWidth() }
}

// MARK: - Pages
enum SummaryPage: CaseIterable, Identifiable {
    case theSplit, weeklyRitual, dailyRhythm, avg
    var id: Self { self }

    var title: String {
        switch self {
        case .theSplit: return "The Split"
        case .weeklyRitual: return "Weekly Ritual"
        case .dailyRhythm:  return "Daily Rhythm"
        case .avg:   return "Avg Miles/Trip"
        }
    }
    var iconName: String {
        switch self {
        case .theSplit: return "gauge"
        case .weeklyRitual: return "chart.bar.xaxis"
        case .dailyRhythm:  return "clock"
        case .avg:   return "ruler"
        }
    }
}

// MARK: - Card Placeholder (to be replaced with live metrics)
struct SummaryCard: View {
    let page: SummaryPage
    let index: Int
    @Environment(\.layout) private var layout

    var body: some View {
        switch page {
        case .theSplit:
            TheSplit
        case .weeklyRitual:
            WeeklyRitual
        case .dailyRhythm:
            DailyRhythm
        default:
            // Generic placeholder for other pages
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: page.iconName)
                    Text(page.title)
                        .font(.headline)
                    Spacer()
                }
                Group {
                    Text("—")
                        .font(.system(size: 34, weight: .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .opacity(0.3)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.quaternary)
                        .frame(height: 22)
                        .opacity(0.35)
                }
            }
            .padding(16)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: SummaryContentHeightKey.self, value: [index: g.size.height])
                }
            )
        }
    }
    
    private var DailyRhythm: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: page.iconName)
                Text(page.title)
                    .font(.headline)
                Spacer()
            }
            Spacer(minLength: 8)
            Group {
                if let hourData = SummaryViewModel.shared.hourData {
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
                        
                        // 6 AM
                        RuleMark(x: .value("6a", 6.0))
                            .lineStyle(.init(lineWidth: 1))
                            .foregroundStyle(.secondary.opacity(0.25))
                            .annotation(position: .bottom, alignment: .center) {
                                Text("6a")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                            }

                        // 12 PM
                        RuleMark(x: .value("12p", 12.0))
                            .lineStyle(.init(lineWidth: 1))
                            .foregroundStyle(.secondary.opacity(0.55))
                            .annotation(position: .bottom, alignment: .center) {
                                Text("12p")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.primary)
                                    .padding(4)
                            }

                        // 6 PM
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
                    .padding(16)
                }
            }
        }
        .padding(16)
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SummaryContentHeightKey.self, value: [index: g.size.height])
            }
        )
    }
    
    func hourLabel(_ h: Int) -> String {
        switch h {
        case 0: return "12a"
        case 12: return "12p"
        case 1...11: return "\(h)a"
        case 13...23: return "\(h - 12)p"
        default: return "" // empty = no label
        }
    }
    
    private var WeeklyRitual: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: page.iconName)
                Text(page.title)
                    .font(.headline)
                Spacer()
            }
            Spacer(minLength: 8)
            Group {
                if let dowData = SummaryViewModel.shared.dowData {
                    Chart {
                        ForEach(Array(dowData.meters.enumerated()), id: \.0) { idx, meters in
                            let norm = meters / max(dowData.maxMeters, 1) // 0…1
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
                            .cornerRadius(3)
                            .annotation(position: .top, alignment: .center) {
                                if meters > 0 {
                                    Text(dowData.valueTexts[idx])
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.bottom, 4)   // 🔹 pushes it upward, away from bar
                                }
                            }
                        }

                        // “Shelf” baseline
                        RuleMark(y: .value("Baseline", 0))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            .foregroundStyle(Color.secondary.opacity(0.4))
                    }
                    .chartYAxis(.hidden)
                    .chartXAxis {
                        AxisMarks(values: dowData.labels) { _ in
                            AxisValueLabel()   // labels only; no ticks/grid
                        }
                    }
                    .chartYScale(domain: 0...(max(dowData.maxMeters, 1)))
                    .frame(height: 140)
                    .padding(16)
                }
            }
        }
        .padding(16)
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SummaryContentHeightKey.self, value: [index: g.size.height])
            }
        )
    }
    
    func hueGreenToRed(_ t: Double) -> Color {
        let clamped = max(0, min(1, t))
        // Hue from ~0.33 (green) down to 0.0 (red)
        return Color(hue: 0.33 * (1 - clamped), saturation: 0.95, brightness: 0.65)
    }
    
    private var TheSplit: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: page.iconName)
                Text(page.title)
                    .font(.headline)
                Spacer()
            }
            Group {
                if let breakdownData = SummaryViewModel.shared.breakdownData {
                    VStack(spacing: 20) {
                        ShareRow(
                            percent: breakdownData.milesPercent,
                            percentLabel: breakdownData.milesPercentLabel,
                            rowLabel: breakdownData.milesLabel,
                            rowDescription: breakdownData.milesDescription,
                            color: .green
                        )
                        ShareRow(
                            percent: breakdownData.durationPercent,
                            percentLabel: breakdownData.durationPercentLabel,
                            rowLabel: breakdownData.durationLabel,
                            rowDescription: breakdownData.durationDescription,
                            color: .blue
                        )
                        ShareRow(
                            percent: breakdownData.tripCountPercent,
                            percentLabel: breakdownData.tripCountPercentLabel,
                            rowLabel: breakdownData.tripCountLabel,
                            rowDescription: breakdownData.tripCountDescription,
                            color: .orange
                        )
                    }
                    .padding(16)
                } else {
                    Text("Unable to pull data for \(TripStatusViewModel.shared.selectedTripType?.name ?? "")")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(
            GeometryReader { g in
                Color.clear.preference(key: SummaryContentHeightKey.self, value: [index: g.size.height])
            }
        )
    }
    
    struct ShareRow: View {
        let percent: Double   // 0…1 ratio
        let percentLabel: String
        let rowLabel: String     // e.g. "Distance"
        let rowDescription: String // e.g. "150 mi / 300 mi"
        let color: Color

        var body: some View {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    Circle()
                        .trim(from: 0, to: percent)
                        .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(percentLabel)
                        .font(.subheadline.bold())
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(rowLabel)
                        .font(.headline)
                    Text(rowDescription)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Indicators (tap to jump)
struct SummaryPageIndicators: View {
    @Binding var currentIndex: Int
    let pages: [SummaryPage]
    @Environment(\.layout) private var layout

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                let isCurrent = (idx == currentIndex)

                Image(systemName: page.iconName)
                    .symbolVariant(isCurrent ? .fill : .none)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(isCurrent ? .primary : .secondary)
                    .scaleEffect(isCurrent ? 1.15 : 1.0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isCurrent ? Color.primary.opacity(0.12) : .clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        guard currentIndex != idx else { return }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                            currentIndex = idx
                        }
                    }
                    .accessibilityLabel(Text(page.title))
                    .accessibilityAddTraits(isCurrent ? .isSelected : [])
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 3)
    }
}

// MARK: - Preview
#Preview {
    SummaryView()
}

fileprivate extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
