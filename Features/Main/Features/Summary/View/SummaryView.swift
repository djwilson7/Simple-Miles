import SwiftUI

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
    case miles, trips, time, avg
    var id: Self { self }

    var title: String {
        switch self {
        case .miles: return "Miles"
        case .trips: return "Trip Count"
        case .time:  return "Active Time"
        case .avg:   return "Avg Miles/Trip"
        }
    }
    var iconName: String {
        switch self {
        case .miles: return "gauge"
        case .trips: return "list.number"
        case .time:  return "clock"
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
        case .miles:
            // Miles-specific skeleton
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: page.iconName)
                    Text(page.title)
                        .font(.headline)
                    Spacer()
                }
                Group {
                    if let milesData = SummaryViewModel.shared.milesData {
                        let ratio = milesData.totalMiles > 0 ? milesData.typeMiles / milesData.totalMiles : 0
                        HStack {
                            //Ring Gauge: Pct of trip type miles compared to all miles (not trash/unsorted miles)
                            Spacer()
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                                Circle()
                                    .trim(from: 0, to: ratio)
                                    .stroke(Color.green, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                                    .rotationEffect(.degrees(180))
                            }
                            .frame(width: 100, height: 100)
                            Spacer()
                        }
                        .padding(16)
                    } else {
                        Text("Unable to pull data for personal")
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
}

// MARK: - Indicators (tap to jump)
struct SummaryPageIndicators: View {
    @Binding var currentIndex: Int
    let pages: [SummaryPage]
    @Environment(\.layout) private var layout

    var body: some View {
        HStack(spacing: 3) {
            ForEach(Array(pages.enumerated()), id: \.offset) { idx, page in
                let isCurrent = (idx == currentIndex)
                VStack(spacing: 4) {
                    Image(systemName: page.iconName)
                        .font(.footnote)
                        .foregroundStyle(isCurrent ? .primary : .secondary)
                    Circle()
                        .frame(width: 6, height: 6)
                        .foregroundStyle(isCurrent ? .primary : .secondary)
                        .opacity(isCurrent ? 1 : 0.3)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard currentIndex != idx else { return }
                    currentIndex = idx
                }
            }
        }
        .padding(.horizontal, 3)
        .padding(.vertical, 3)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(.quaternary, lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview {
    SummaryView()
}

fileprivate extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
