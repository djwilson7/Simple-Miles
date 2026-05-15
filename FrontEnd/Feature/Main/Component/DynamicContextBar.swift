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
    @State private var desiredHeight: CGFloat = 200
    @State private var desiredWidth: CGFloat = 200

    // MARK: - Configuration
    private var minWidth: CGFloat { layout.halfBarWidth }
    private var minHeight: CGFloat { min(layout.height.pct(0.1), layout.width.pct(0.1)) }

    private var currentCornerRadius: CGFloat {
        (mainState.state == .settings || mainState.state == .summary) ? 60 : layout.cornerRadius
    }
    
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
        let isImmersive = (mainState.state == .settings || mainState.state == .summary)
        let topRadius = layout.cornerRadius
        let bottomRadius = isImmersive ? 0 : layout.cornerRadius
        
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: topRadius,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: topRadius
        )

        ZStack(alignment: .bottom) {
            contentForState
                .padding(20)
                .id(mainState.state)
                .transition(.opacity.animation(.easeInOut(duration: layout.animationDurations.fast)))
        }
        .frame(width: desiredWidth, height: desiredHeight, alignment: .bottom)
        .applyMaterial(in: shape)
        .animation(.spring(duration: layout.animationDurations.fast), value: mainState.state)
        .clipShape(shape)
        .contentShape(shape)
        .onPreferenceChange(DynamicContextBarDesiredHeightKey.self) { newValue in
            guard newValue > 0 else { return }
            let totalVerticalPadding: CGFloat = 40 // 20pt top + 20pt bottom
            withAnimation(.spring(duration: layout.animationDurations.fast)) {
                desiredHeight = max(minHeight, newValue + totalVerticalPadding)
            }
        }
        .onPreferenceChange(DynamicContextBarDesiredWidthKey.self) { newValue in
            guard newValue > 0 else { return }
            let totalHorizontalPadding: CGFloat = 40 // 20pt left + 20pt right
            withAnimation(.spring(duration: layout.animationDurations.fast)) {
                desiredWidth = max(minWidth, newValue + totalHorizontalPadding)
            }
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
}
