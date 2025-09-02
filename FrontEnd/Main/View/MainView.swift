import MapKit
import SwiftUI
import UIKit

/// Hosts the primary map screen and the bottom context bar.
/// Orchestrates overlays (title, controls, review actions) and drag-to-classify UI.
struct MainView: View {

    // MARK: - Types (View-only helpers)
    struct BarFrameKey: PreferenceKey {
        static var defaultValue: Anchor<CGRect>? = nil
        static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
            if let next = nextValue() { value = next }
        }
    }

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout

    @ObservedObject var mainViewModel: MainViewModel
    @ObservedObject var mapViewModel: MapViewModel
    @ObservedObject var snapshotViewModel = SnapshotViewModel.shared

    // MARK: - State
    @State private var barDrag: CGSize = .zero
    @State private var islandOffset: CGFloat = 0
    @State private var highlighted: TripType? = nil
    @State private var isDragging: Bool = false
    @State private var currentHighlightedArea: CGFloat = 0
    @State private var optionAnchorsState: [TripType: Anchor<CGRect>] = [:]
    @State private var barAnchorState: Anchor<CGRect>? = nil
    @State private var overlayProxy: GeometryProxy? = nil

    // MARK: - Computed
    private var isReview: Bool { MainStateManager.shared.state == .review }
    private var canGoPrev: Bool { SortViewModel.shared.currentTripIndex > 0 }
    private var canGoNext: Bool {
        SortViewModel.shared.currentTripIndex < SortViewModel.shared.tripCount - 1
    }
    // Centralized condition for action buttons visibility
    private var showActionButtons: Bool {
        MainStateManager.shared.state == .main &&
        snapshotViewModel.selectedTripType != nil
    }

    // MARK: - Private Dependencies
    private let tripViewModel = SortViewModel.shared
    private let settings = SettingsManager.shared

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapView(viewModel: mapViewModel)

                SortOptionsBGView(highlighted: highlighted)
                    .opacity(isReview && isDragging ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isDragging)

                SortOptionsView(highlighted: highlighted)
                    .opacity(isReview && isDragging ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isDragging)

                ZStack {
                    contextBar(geo: geo)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .overlay(alignment: .top) {
            titleBar
                .uiBlock(.title)
        }
        .overlay(alignment: .trailing) {
            controlButtons
                .uiBlock(.row)
        }
        .overlay(alignment: .bottomLeading) {
            previousButton
                .uiBlock(.title)
        }
        .overlay(alignment: .bottomTrailing) {
            nextButton
                .uiBlock(.title)
        }
        // Scrim + action buttons overlay
        .overlay {
            ZStack {
                actionButtonsScrim
                VStack {
                    Spacer(minLength: layout.height.pct(0.75))
                    HStack {
                        Spacer()
                        reviewButton
                        Spacer()
                        summaryButton
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .overlay(alignment: .topLeading) {
            backButton
                .uiBlock(.title)
        }
        .overlay(alignment: .topTrailing) {
            extendPauseButton
                .uiBlock(.title)
        }
        .overlayPreferenceValue(SortOptionsView.Types.OptionFramesKey.self) { optionAnchors in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        overlayProxy = proxy
                        optionAnchorsState = optionAnchors
                        updateHighlight(
                            proxy: proxy,
                            optionAnchors: optionAnchorsState,
                            barAnchor: barAnchorState,
                            highlighted: &highlighted,
                            currentHighlightedArea: &currentHighlightedArea,
                            drag: barDrag
                        )
                    }
                    .onChange(of: optionAnchors, initial: true) { _, newValue in
                        overlayProxy = proxy
                        optionAnchorsState = newValue
                        updateHighlight(
                            proxy: proxy,
                            optionAnchors: optionAnchorsState,
                            barAnchor: barAnchorState,
                            highlighted: &highlighted,
                            currentHighlightedArea: &currentHighlightedArea,
                            drag: barDrag
                        )
                    }
            }
        }
        .overlayPreferenceValue(MainView.BarFrameKey.self) { barAnchor in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        overlayProxy = proxy
                        barAnchorState = barAnchor
                        updateHighlight(
                            proxy: proxy,
                            optionAnchors: optionAnchorsState,
                            barAnchor: barAnchorState,
                            highlighted: &highlighted,
                            currentHighlightedArea: &currentHighlightedArea,
                            drag: barDrag
                        )
                    }
                    .onChange(of: barDrag, initial: true) { _, _ in
                        updateHighlight(
                            proxy: proxy,
                            optionAnchors: optionAnchorsState,
                            barAnchor: barAnchorState,
                            highlighted: &highlighted,
                            currentHighlightedArea: &currentHighlightedArea,
                            drag: barDrag
                        )
                    }
                    .onChange(of: barAnchor, initial: true) { _, newValue in
                        overlayProxy = proxy
                        barAnchorState = newValue
                        updateHighlight(
                            proxy: proxy,
                            optionAnchors: optionAnchorsState,
                            barAnchor: barAnchorState,
                            highlighted: &highlighted,
                            currentHighlightedArea: &currentHighlightedArea,
                            drag: barDrag
                        )
                    }
            }
        }
    }

    // MARK: - Subviews
    private var titleBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: layout.radii.pill)
                .fill(Color.clear)

            TimelineView(.animation) { _ in
                let start: CGFloat = 0.75
                let isPaused = TravelStateManager.shared.state == .paused
                if isPaused, let snap = mainViewModel.pauseSnapshot {
                    let remaining = max(0, snap.end.timeIntervalSinceNow)
                    let total = max(0.001, snap.total)
                    let progress = max(0, min(1, 1 - (remaining / total)))
                    let rawEnd = start + CGFloat(progress)

                    ZStack {
                        if rawEnd <= 1.0 {
                            RoundedRectangle(cornerRadius: layout.radii.pill)
                                .trim(from: start, to: rawEnd)
                                .stroke(Color.orange.opacity(0.9), lineWidth: 3)
                        } else {
                            RoundedRectangle(cornerRadius: layout.radii.pill)
                                .trim(from: start, to: 1.0)
                                .stroke(Color.orange.opacity(0.9), lineWidth: 3)

                            RoundedRectangle(cornerRadius: layout.radii.pill)
                                .trim(from: 0.0, to: rawEnd - 1.0)
                                .stroke(Color.orange.opacity(0.9), lineWidth: 3)
                        }
                    }
                }
            }

            TimelineView(.animation) { _ in
                HStack {
                    Spacer()
                    if mainViewModel.travelState == .paused
                        && mainViewModel.state == .main,
                       let snap = mainViewModel.pauseSnapshot
                    {
                        let remaining = max(0, snap.end.timeIntervalSinceNow)
                        Text(TimeUtility.formatter(remaining))
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .uiText(.title)
                            .id(snap.id)
                    } else {
                        Text(mainViewModel.title)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .uiText(.title)
                    }
                    Spacer()
                }
                .uiBlock(.title)
            }
        }
        .frame(width: layout.width.pct(0.5), height: layout.height.pct(0.2))
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .applyMaterial()
    }

    private func contextBar(geo: GeometryProxy) -> some View {
        DynamicContextBar(
            tripStatusContent: { SnapshotView() },
            settingsContent: { SettingsView() },
            reviewContent: { SortView() },
            summaryContent: { SummaryView() }
        )
        .applyMaterial()
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .offset(isReview ? barDrag : .zero)
        .anchorPreference(key: MainView.BarFrameKey.self, value: .bounds) { $0 }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if isReview {
                        barDrag = value.translation
                        if isDragging == false {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        isDragging = true
                        updateHighlight(
                            proxy: overlayProxy ?? geo,
                            optionAnchors: optionAnchorsState,
                            barAnchor: barAnchorState,
                            highlighted: &highlighted,
                            currentHighlightedArea: &currentHighlightedArea,
                            drag: barDrag
                        )
                    }
                }
                .onEnded { _ in
                    if isReview {
                        if let selected = highlighted {
                            tripViewModel.classifyCurrentSegment(newType: selected)
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                        }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            barDrag = .zero
                            isDragging = false
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        highlighted = nil
                        currentHighlightedArea = 0
                    }
                }
        )
        .animation(.spring(duration: layout.animationDurations.medium), value: barDrag)
    }

    private var previousButton: some View {
        let leftVisible = isReview && canGoPrev
        let dragging = isReview && (barDrag != .zero)
        let visible = leftVisible && !dragging

        return CustomButton(
            isVisible: visible,
            color: AppTheme.Colors.primaryText,
            action: { SortViewModel.shared.selectPreviousSegment() },
            icon: "chevron.left"
        )
    }

    private var nextButton: some View {
        let rightVisible = isReview && canGoNext
        let dragging = isReview && (barDrag != .zero)
        let visible = rightVisible && !dragging

        return CustomButton(
            isVisible: visible,
            color: AppTheme.Colors.primaryText,
            action: { SortViewModel.shared.selectNextSegment() },
            icon: "chevron.right"
        )
    }

    private var controlButtons: some View {
        VStack(spacing: 10) {
            settingsButton
            shareButton
            recenterButton
        }
    }

    private var recenterButton: some View {
        CustomButton(
            isVisible: MainStateManager.shared.state == .main,
            color: AppTheme.Colors.primaryText,
            action: { mapViewModel.recenter() },
            icon: mapViewModel.locationIconName
        )
    }

    private var shareButton: some View {
        CustomButton(
            isVisible: MainStateManager.shared.state == .main,
            color: AppTheme.Colors.primaryText,
            action: { /* TODO */ },
            icon: "square.and.arrow.up"
        )
    }

    private var settingsButton: some View {
        CustomButton(
            isVisible: MainStateManager.shared.state == .main,
            color: AppTheme.Colors.primaryText,
            action: { mainViewModel.settingsTapped() },
            icon: "gearshape"
        )
    }

    private var reviewButton: some View {
        CustomButton(
            isVisible: showActionButtons,
            color: AppTheme.Colors.primaryText,
            action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                MainStateManager.shared.state = .review
                Log("Entering Review State for \(String(describing: snapshotViewModel.selectedTripType))")
            },
            icon: "rectangle.and.text.magnifyingglass",
            text: snapshotViewModel.selectedTripType.map { "\($0) Review" }?.capitalized
        )
    }

    private var summaryButton: some View {
        CustomButton(
            isVisible: showActionButtons,
            color: AppTheme.Colors.primaryText,
            action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                MainStateManager.shared.state = .summary
                Log("Entering Review State for \(String(describing: snapshotViewModel.selectedTripType))")
            },
            icon: "chart.bar",
            text: snapshotViewModel.selectedTripType.map { "\($0) Summary" }?.capitalized
        )
    }

    private var backButton: some View {
        CustomButton(
            isVisible: MainStateManager.shared.state != .main,
            color: AppTheme.Colors.primaryText,
            action: { MainStateManager.shared.state = .main },
            icon: "chevron.left"
        )
    }

    private var extendPauseButton: some View {
        CustomButton(
            isVisible: TravelStateManager.shared.state == .paused,
            color: .orange,
            action: { TravelStateManager.shared.extendPauseTimer() },
            icon: "plus"
        )
    }

    private var actionButtonsScrim: some View {
        Color.black
            .opacity(0.35)
            .ignoresSafeArea()
            .opacity(showActionButtons ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showActionButtons)
            .allowsHitTesting(showActionButtons)
            .onTapGesture {
                snapshotViewModel.clearSelected()
            }
    }
}

// MARK: - Helpers (free function kept file-private for locality)
@MainActor
fileprivate func updateHighlight(
    proxy: GeometryProxy,
    optionAnchors: [TripType: Anchor<CGRect>],
    barAnchor: Anchor<CGRect>?,
    highlighted: inout TripType?,
    currentHighlightedArea: inout CGFloat,
    drag: CGSize
) {
    if MainStateManager.shared.state != .review {
        highlighted = nil
        currentHighlightedArea = 0
        return
    }
    guard let barAnchor = barAnchor else {
        highlighted = nil
        currentHighlightedArea = 0
        return
    }
    if optionAnchors.isEmpty {
        highlighted = nil
        currentHighlightedArea = 0
        return
    }

    let baseRect = proxy[barAnchor]
    let barRect = baseRect.offsetBy(dx: drag.width, dy: drag.height)

    var best: (opt: TripType, area: CGFloat)? = nil
    for (opt, anchor) in optionAnchors {
        let rect = proxy[anchor]
        let inter = barRect.intersection(rect)
        let area = max(inter.width, 0) * max(inter.height, 0)
        if area > 0 {
            if best == nil || area > best!.area { best = (opt, area) }
        }
    }

    let hysteresis: CGFloat = 1.10
    if let candidate = best {
        if let current = highlighted {
            if candidate.opt == current {
                currentHighlightedArea = candidate.area
            } else if candidate.area >= currentHighlightedArea * hysteresis {
                highlighted = candidate.opt
                currentHighlightedArea = candidate.area
            }
        } else {
            highlighted = candidate.opt
            currentHighlightedArea = candidate.area
        }
    } else {
        highlighted = nil
        currentHighlightedArea = 0
    }
}
