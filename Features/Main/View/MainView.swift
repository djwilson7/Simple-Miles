import SwiftUI
import MapKit

struct MainView: View {
    @Environment(\.layout) private var layout
    
    @ObservedObject var mainviewModel: MainViewModel
    @ObservedObject var mapViewModel: MapViewModel
    
    @State private var barDrag: CGSize = .zero
    @State private var islandOffset: CGFloat = 0
    @State var highlighted: TripType? = nil
    @State var isDragging: Bool = false
    @State var currentHighlightedArea: CGFloat = 0
    @State var optionAnchorsState: [TripType: Anchor<CGRect>] = [:]
    @State var barAnchorState: Anchor<CGRect>? = nil
    @State private var overlayProxy: GeometryProxy? = nil
    
    private var isReview: Bool { MainStateDriver.shared.mainState == .review }
    private var canGoPrev: Bool { TripViewModel.shared.currentTripIndex > 0 }
    private var canGoNext: Bool { TripViewModel.shared.currentTripIndex < TripViewModel.shared.unclassifiedSegments.count - 1 }
    
    private let tripViewModel = TripViewModel.shared
    
    var body: some View {
        GeometryReader { geo in
            
            ZStack {
                MapView(viewModel: mapViewModel)
                
                GeometryReader { safeGeo in
                    VStack {
                        VStack {
                            Spacer()
                            TitleBarView()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.1)
                        
                        ZStack {
                            GlassEffectContainer {
                                ZStack(alignment: .center) {
                                    TripSortingBackgroundView(highlighted: highlighted)
                                        .opacity(isDragging ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.3), value: isDragging)
                                    
                                    ZStack {
                                        previousButton
                                        contextBar(geo: geo)
                                        nextButton
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.9, alignment: .bottom)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            .frame(height: geo.size.height * 0.9)
                            
                            TripSortingTextView(highlighted: highlighted)
                                .opacity(isDragging ? 1 : 0)
                                .animation(.easeInOut(duration: 0.3), value: isDragging)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(maxHeight: .infinity)
            }
        }
        
        .overlay(alignment: .trailing) {
            if MainStateDriver.shared.mainState == .main {
                controlButtons
            }
        }
        .overlayPreferenceValue(OptionFramesKey.self) { optionAnchors in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        overlayProxy = proxy
                        optionAnchorsState = optionAnchors
                        updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: barDrag)
                    }
                    .onChange(of: optionAnchors, initial: true) { _, newValue in
                        overlayProxy = proxy
                        optionAnchorsState = newValue
                        updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: barDrag)
                    }
            }
        }
        .overlayPreferenceValue(BarFrameKey.self) { barAnchor in
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        overlayProxy = proxy
                        barAnchorState = barAnchor
                        updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: barDrag)
                    }
                    .onChange(of: barDrag, initial: true) { _, newValue in
                        updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: barDrag)
                    }
                    .onChange(of: barAnchor, initial: true) { _, newValue in
                        overlayProxy = proxy
                        barAnchorState = newValue
                        updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: barDrag)
                    }
            }
        }
    }
    
    private var previousButton: some View {
        let leftVisible = isReview && canGoPrev
        let isDragging = isReview && (barDrag != .zero)
        let followX = isDragging ? barDrag.width : 0
        let followY = isDragging ? barDrag.height : 0
        let visibleX = -layout.contextButtonOffset
        return SystemControlButton( //Left Button
            opacity: !leftVisible || isDragging ? 0 : 1,
            color: AppTheme.Colors.primaryText,
            action: { TripViewModel.shared.selectPreviousSegment() },
            label: { AnimatedChevronButtonLabel(isLeftFacing: true) }
        )
        .offset(x: isDragging ? followX : (leftVisible ? visibleX : 0), y: isDragging ? followY : 0)
        .allowsHitTesting(leftVisible)
        .animation(.spring(duration: layout.animationDurations.medium), value: barDrag)
        .animation(.spring(duration: layout.animationDurations.slow), value: leftVisible)
    }
    
    private var nextButton: some View {
        let rightVisible = isReview && canGoNext
        let isDragging = isReview && (barDrag != .zero)
        let followX = isDragging ? barDrag.width : 0
        let followY = isDragging ? barDrag.height : 0
        let visibleX = layout.contextButtonOffset
        return SystemControlButton(
            opacity: !rightVisible || isDragging ? 0 : 1,
            color: AppTheme.Colors.primaryText,
            action: { TripViewModel.shared.selectNextSegment() },
            label: { AnimatedChevronButtonLabel(isLeftFacing: false) }
        )
        .offset(x: isDragging ? followX : (rightVisible ? visibleX : 0), y: isDragging ? followY : 0)
        .allowsHitTesting(rightVisible)
        .animation(.spring(duration: layout.animationDurations.medium), value: barDrag)
        .animation(.spring(duration: layout.animationDurations.slow), value: rightVisible)
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
            }
        )
        .glassEffect(in: RoundedRectangle(cornerRadius: layout.radii.pill))
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .offset(isReview ? barDrag : .zero)
        .anchorPreference(key: BarFrameKey.self, value: .bounds) { $0 }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if isReview {
                        barDrag = value.translation
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
                            tripViewModel.classifyCurrentSegment(newType: selected)
                        }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            barDrag = .zero
                            isDragging = false
                        }
                        // Clear highlight after commit/reset
                        highlighted = nil
                        currentHighlightedArea = 0
                    }
                }
        )
        .animation(.spring(duration: layout.animationDurations.medium), value: barDrag)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 10) {
            settingsButton
            shareButton
            summaryButton
            recenterButton
        }
        .padding(.trailing, layout.controlButtonsPadding - islandOffset)
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main) { _ in
                switch UIDevice.current.orientation {
                case .landscapeLeft:
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                        islandOffset = window.safeAreaInsets.right
                    }
                default:
                    islandOffset = 0
                }
            }
        }
    }
    
    private var recenterButton: some View {
        SystemControlButton(
            color: AppTheme.Colors.primaryText,
            action: { mapViewModel.recenter() },
            label: { Image(systemName: mapViewModel.locationIconName) }
        )
    }
    
    private var shareButton: some View {
        SystemControlButton(
            color: AppTheme.Colors.primaryText,
            action: { /* TODO */ },
            label: { Image(systemName: "square.and.arrow.up") }
        )
    }
    
    private var settingsButton: some View {
        SystemControlButton(
            color: AppTheme.Colors.primaryText,
            action: { mainviewModel.settingsTapped() },
            label: { Image(systemName: "gearshape") }
        )
    }
    
    private var summaryButton: some View {
        SystemControlButton(
            color: AppTheme.Colors.primaryText,
            action: { mainviewModel.summaryTapped() },
            label: { Image(systemName: "rectangle.stack") }
        )
    }
}

func updateHighlight(
    proxy: GeometryProxy,
    optionAnchors: [TripType: Anchor<CGRect>],
    barAnchor: Anchor<CGRect>?,
    highlighted: inout TripType?,
    currentHighlightedArea: inout CGFloat,
    drag: CGSize
) {
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
        mainviewModel: MainViewModel(),
        mapViewModel: MapViewModel()
    )
}
