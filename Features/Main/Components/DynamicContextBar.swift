import SwiftUI

struct DynamicContextBar<TripStatusContent: View, SettingsContent: View, ReviewContent: View, SummaryContent: View>: View {
    @Environment(\.layout) private var layout
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel = DynamicContextBarViewModel.shared
    @State private var animatedHeight: CGFloat = 200
    @State private var animatedWidth: CGFloat = 200
    @State private var animateTask: Task<Void, Never>? = nil
    @State private var showContent = true
    @State private var targetSize: CGSize = .zero
    @State private var desiredHeight: CGFloat = 200
    @State private var desiredWidth: CGFloat = 200
    
    var minWidth: CGFloat { layout.width.pct(0.3) }
    var minHeight: CGFloat { max(40, layout.height.pct(0.05)) }
        
    let tripStatusContent: () -> TripStatusContent
    let settingsContent: () -> SettingsContent
    let reviewContent: () -> ReviewContent
    let summaryContent: () -> SummaryContent
    
    var body: some View {
        ZStack {
            if !showContent {
                ProgressView()
            }
            if showContent {
                switch viewModel.mainState {
                case .main:
                    tripStatusContent()
                        .appPadding(.all, layout.spacing.m)
                case .settings:
                    ScrollView {
                        settingsContent()
                            .appPadding(.all, layout.spacing.m)
                    }
                case .review:
                    reviewContent()
                        .appPadding(.all, layout.spacing.m)
                case .summary:
                    summaryContent()
                        .appPadding(.all, layout.spacing.m)
                }
            }
        }
        .id(colorScheme)
        .frame(width: animatedWidth, height: animatedHeight, alignment: .center)
        .onChange(of: viewModel.mainState) { _, _ in
            runContentTransitionAnimation()
        }
        .onChange(of: colorScheme) { _, _ in
            runContentTransitionAnimation()
        }
        .onPreferenceChange(DynamicContextBarDesiredHeightKey.self) { newValue in
            desiredHeight = max(minHeight, newValue)
            if showContent {
                withAnimation(.easeInOut(duration: layout.animationDurations.fast)) {
                    animatedHeight = desiredHeight
                }
            }
        }
        .onPreferenceChange(DynamicContextBarDesiredWidthKey.self) { newValue in
            desiredWidth = max(minWidth, newValue)
            if showContent {
                withAnimation(.easeInOut(duration: layout.animationDurations.fast)) {
                    animatedWidth = desiredWidth
                }
            }
        }
        .onAppear {
            animatedHeight = desiredHeight
            animatedWidth = max(minWidth, desiredWidth)
        }
        .onDisappear { animateTask?.cancel() }
    }
    // MARK: - Private helpers
    private func runContentTransitionAnimation() {
        animateTask?.cancel()
        animateTask = Task {
            await MainActor.run {
                showContent = false
                withAnimation(.easeInOut(duration: layout.animationDurations.fast)) {
                    animatedHeight = minHeight
                    animatedWidth = minWidth
                }
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: layout.animationDurations.medium)) {
                    animatedHeight = desiredHeight
                    animatedWidth = desiredWidth
                }
            }
            try? await Task.sleep(nanoseconds: UInt64(layout.animationDurations.medium * 1_000_000_000))
            await MainActor.run {
                showContent = true
            }
        }
    }
}
