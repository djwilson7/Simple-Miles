import SwiftUI

// MARK: - Preference Keys
struct DynamicContextBarDesiredHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct DynamicContextBarDesiredWidthKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// A reusable, size-adapting container that hosts different feature views (status, settings, review, summary)
/// and animates its size/transition based on child-reported intrinsic width/height via preferences.
struct DynamicContextBar<TripStatusContent: View, SettingsContent: View, ReviewContent: View, SummaryContent: View>: View {

    // MARK: - Environment
    @Environment(\.layout) private var layout

    // MARK: - Dependencies
    @ObservedObject private var mainState = MainStateManager.shared

    // MARK: - Inputs
    let tripStatusContent: () -> TripStatusContent
    let settingsContent: () -> SettingsContent
    let reviewContent: () -> ReviewContent
    let summaryContent: () -> SummaryContent

    // MARK: - State
    @State private var animatedHeight: CGFloat = 200
    @State private var animatedWidth: CGFloat = 200
    @State private var animateTask: Task<Void, Never>? = nil
    @State private var showContent = true
    @State private var desiredHeight: CGFloat = 200
    @State private var desiredWidth: CGFloat = 200

    // MARK: - Configuration
    private var minWidth: CGFloat { min(layout.width.pct(0.95), layout.height.pct(0.95)) }
    private var minHeight: CGFloat { min(layout.height.pct(0.1), layout.width.pct(0.1)) }
    
    // MARK: - Init
    init(
        tripStatusContent: @escaping () -> TripStatusContent,
        settingsContent: @escaping () -> SettingsContent,
        reviewContent: @escaping () -> ReviewContent,
        summaryContent: @escaping () -> SummaryContent
    ) {
        self.tripStatusContent = tripStatusContent
        self.settingsContent = settingsContent
        self.reviewContent = reviewContent
        self.summaryContent = summaryContent
    }

    // MARK: - Body
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: layout.radii.pill)

        ZStack {
            if !showContent {
                ProgressView()
            }
            if showContent {
                contentForState
                    .uiBlock(.title)
            }
        }
        .frame(width: animatedWidth, height: animatedHeight, alignment: .center)
        .clipShape(shape)
        .contentShape(shape)
        .onChange(of: mainState.state) { _, _ in
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
        .onDisappear {
            animateTask?.cancel()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Context Bar"))
    }

    // MARK: - Subviews
    @ViewBuilder
    private var contentForState: some View {
        switch mainState.state {
        case .main:
            tripStatusContent()
        case .settings:
            settingsContent()
        case .review:
            reviewContent()
        case .summary:
            summaryContent()
        }
    }

    // MARK: - Actions
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
            let mediumNs = UInt64(layout.animationDurations.medium * 1_000_000_000)
            try? await Task.sleep(nanoseconds: mediumNs)
            await MainActor.run {
                showContent = true
            }
        }
    }
}
