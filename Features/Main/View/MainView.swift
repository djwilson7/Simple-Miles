import MapKit
import SwiftUI
import UIKit

struct MainView: View {
    @Environment(\.layout) private var layout

    @ObservedObject var mainViewModel: MainViewModel
    @ObservedObject var mapViewModel: MapViewModel

    @State private var barDrag: CGSize = .zero
    @State private var islandOffset: CGFloat = 0
    @State var highlighted: TripType? = nil
    @State var isDragging: Bool = false
    @State var currentHighlightedArea: CGFloat = 0
    @State var optionAnchorsState: [TripType: Anchor<CGRect>] = [:]
    @State var barAnchorState: Anchor<CGRect>? = nil
    @State private var overlayProxy: GeometryProxy? = nil
    @StateObject private var subMenuVM = TripSubMenuViewModel.shared

    private var isReview: Bool { MainStateDriver.shared.mainState == .review }
    private var canGoPrev: Bool { TripViewModel.shared.currentTripIndex > 0 }
    private var canGoNext: Bool {
        TripViewModel.shared.currentTripIndex < TripViewModel.shared.tripCount
            - 1
    }

    private let tripViewModel = TripViewModel.shared
    private let settings = SettingsCenter.shared

    var body: some View {
        GeometryReader { geo in
            ZStack {
                MapView(viewModel: mapViewModel)

                TripSortingBackgroundView(highlighted: highlighted)
                    .opacity(isReview && isDragging ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isDragging)

                TripSortingTextView(highlighted: highlighted)
                    .opacity(isReview && isDragging ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: isDragging)

                ZStack {
                    contextBar(geo: geo)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .bottom
                )
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

        .overlay {
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

        .overlay(alignment: .topLeading) {
            backButton
                .uiBlock(.title)
        }

        .overlay(alignment: .topTrailing) {
            extendPauseButton
                .uiBlock(.title)
        }

        .overlayPreferenceValue(OptionFramesKey.self) { optionAnchors in
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

        .overlayPreferenceValue(BarFrameKey.self) { barAnchor in
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
                    .onChange(of: barDrag, initial: true) { _, newValue in
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

    private var titleBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: layout.radii.pill)
                .fill(Color.clear)

            TimelineView(.animation) { _ in
                let start: CGFloat = 0.75
                let isPaused = TravelStateManager.shared.state == .paused
                if isPaused, let snap = mainViewModel.pauseSnapshot {
                    let remaining = max(0, snap.end.timeIntervalSinceNow)
                    let total = max(0.001, snap.total)  // avoid divide-by-zero
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
        .frame(width: layout.elementWidth, height: layout.titleHeight)
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .applyMaterial()
        .onTapGesture {
            TripSubMenuViewModel.shared.isVisible = false
        }
    }

    private func contextBar(geo: GeometryProxy) -> some View {
        DynamicContextBar(
            tripStatusContent: {
                TripStatusView()
            },
            settingsContent: {
                SettingsView()
            },
            reviewContent: {
                TripSortingView()
            },
            summaryContent: {
                SummaryView()
            }
        )
        .applyMaterial()
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .offset(isReview ? barDrag : .zero)
        .anchorPreference(key: BarFrameKey.self, value: .bounds) { $0 }
        .onTapGesture {
            TripSubMenuViewModel.shared.isVisible = false
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if isReview {
                        barDrag = value.translation
                        if isDragging == false {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
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
                        // Commit sort if a target was highlighted at drop
                        if let selected = highlighted {
                            tripViewModel.classifyCurrentSegment(
                                newType: selected
                            )
                            UINotificationFeedbackGenerator()
                                .notificationOccurred(.success)
                        }
                        withAnimation(
                            .spring(response: 0.35, dampingFraction: 0.8)
                        ) {
                            barDrag = .zero
                            isDragging = false
                        }
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                        highlighted = nil
                        currentHighlightedArea = 0
                    }
                }
        )
        .animation(
            .spring(duration: layout.animationDurations.medium),
            value: barDrag
        )
    }

    private var previousButton: some View {
        let leftVisible = isReview && canGoPrev
        let isDragging = isReview && (barDrag != .zero)
        let visible = leftVisible && !isDragging

        return CustomButton(  //Left Button
            isVisible: visible,
            color: AppTheme.Colors.primaryText,
            action: { TripViewModel.shared.selectPreviousSegment() },
            icon: "chevron.left"
        )
    }

    private var nextButton: some View {
        let rightVisible = isReview && canGoNext
        let isDragging = isReview && (barDrag != .zero)
        let visible = rightVisible && !isDragging

        return CustomButton(
            isVisible: visible,
            color: AppTheme.Colors.primaryText,
            action: { TripViewModel.shared.selectNextSegment() },
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
            isVisible: MainStateDriver.shared.mainState == .main,
            color: AppTheme.Colors.primaryText,
            action: { mapViewModel.recenter() },
            icon: mapViewModel.locationIconName
        )
    }

    private var shareButton: some View {
        CustomButton(
            isVisible: MainStateDriver.shared.mainState == .main,
            color: AppTheme.Colors.primaryText,
            action: { /* TODO */  },
            icon: "square.and.arrow.up"
        )
    }

    private var settingsButton: some View {
        CustomButton(
            isVisible: MainStateDriver.shared.mainState == .main,
            color: AppTheme.Colors.primaryText,
            action: { mainViewModel.settingsTapped() },
            icon: "gearshape"
        )
    }

    private var reviewButton: some View {
        CustomButton(
            isVisible: subMenuVM.isVisible,
            color: AppTheme.Colors.primaryText,
            action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                TripSubMenuViewModel.shared.hide()
                MainStateDriver.shared.mainState = .review
                Log(
                    "Entering Review State for \(String(describing: TripStatusViewModel.shared.selectedTripType))"
                )
            },
            icon: "rectangle.and.text.magnifyingglass",
            text: TripStatusViewModel.shared.selectedTripType.map {
                "\($0) Review"
            }?.capitalized

        )
        .opacity(subMenuVM.isVisible ? 1 : 0)
        .animation(
            .spring(response: 0.55, dampingFraction: 0.85),
            value: subMenuVM.isVisible
        )
    }

    private var summaryButton: some View {
        CustomButton(
            isVisible: subMenuVM.isVisible,
            color: AppTheme.Colors.primaryText,
            action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                TripSubMenuViewModel.shared.hide()
                MainStateDriver.shared.mainState = .summary
                Log(
                    "Entering Review State for \(String(describing: TripStatusViewModel.shared.selectedTripType))"
                )
            },
            icon: "chart.bar",
            text: TripStatusViewModel.shared.selectedTripType.map {
                "\($0) Summary"
            }?.capitalized

        )
        .animation(
            .spring(response: 0.55, dampingFraction: 0.85),
            value: subMenuVM.isVisible
        )
    }

    private var backButton: some View {
        CustomButton(
            isVisible: MainStateDriver.shared.mainState != .main,
            color: AppTheme.Colors.primaryText,
            action: { MainStateDriver.shared.mainState = .main },
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
}

@MainActor func updateHighlight(
    proxy: GeometryProxy,
    optionAnchors: [TripType: Anchor<CGRect>],
    barAnchor: Anchor<CGRect>?,
    highlighted: inout TripType?,
    currentHighlightedArea: inout CGFloat,
    drag: CGSize
) {
    if MainStateDriver.shared.mainState != .review {
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

#Preview {
    MainView(
        mainViewModel: MainViewModel(),
        mapViewModel: MapViewModel()
    )
}
