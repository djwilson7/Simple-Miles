import SwiftUI
import MapKit

struct MainView: View {
    @ObservedObject var mainviewModel: MainViewModel
    @ObservedObject var mapViewModel: MapViewModel
    @State private var barDrag: CGSize = .zero
    @State private var islandOffset: CGFloat = 0
    @Environment(\.layout) private var layout
    
    private var isReview: Bool { MainStateDriver.shared.mainState == .review }
    private var canGoPrev: Bool { TripViewModel.shared.currentTripIndex > 0 }
    private var canGoNext: Bool { TripViewModel.shared.currentTripIndex < TripViewModel.shared.unclassifiedSegments.count - 1 }
    
    var body: some View {
        GeometryReader { geo in
            let safeHeight = geo.size.height - geo.safeAreaInsets.top - geo.safeAreaInsets.bottom
            
            ZStack {
                MapView(viewModel: mapViewModel)
                
                GeometryReader { safeGeo in
                    VStack {
                            VStack {
                                Spacer()
                                TitleBarView()
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: safeGeo.size.height * 0.1)

                            GlassEffectContainer {
                                ZStack {
                                    previousButton
                                    contextBar
                                    nextButton
                                }
                                .frame(maxWidth: .infinity, maxHeight: safeHeight * 0.9, alignment: .bottom)
                            }
                            .frame(maxWidth: .infinity, alignment: .bottom)
                            .frame(height: safeGeo.size.height * 0.9)
                        
                    }
                    .frame(height: safeHeight)
                }
                .frame(height: safeHeight)
            }
        }
        
        .overlay(alignment: .trailing) {
            if MainStateDriver.shared.mainState == .main {
                controlButtons
            }
        }
    }
    
    private var previousButton: some View {
        let leftVisible = isReview && canGoPrev
        let isDragging = isReview && (barDrag != .zero)
        let followX = isDragging ? barDrag.width : 0
        let followY = isDragging ? barDrag.height : 0
        let visibleX = -layout.width.pct(0.4)
        return SystemControlButton( //Left Button
            opacity: !leftVisible || isDragging ? 0 : 1,
            color: Color.white,
            action: { TripViewModel.shared.selectPreviousSegment() },
            label: { AnimatedChevronButtonLabel(isLeftFacing: true) }
        )
        .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        .buttonStyle(.plain)
        .glassEffect(.clear)
        .opacity(!leftVisible || isDragging ? 0 : 1)
        .offset(x: isDragging ? followX : (leftVisible ? visibleX : 0),
                y: isDragging ? followY : 0)
        .allowsHitTesting(leftVisible)
        .animation(.spring(duration: layout.animationDurations.medium), value: barDrag)
        .animation(.spring(duration: layout.animationDurations.slow), value: leftVisible)
    }
    
    private var nextButton: some View {
        let rightVisible = isReview && canGoNext
        let isDragging = isReview && (barDrag != .zero)
        let followX = isDragging ? barDrag.width : 0
        let followY = isDragging ? barDrag.height : 0
        let visibleX = layout.width.pct(0.4)
        return SystemControlButton(
            opacity: !rightVisible || isDragging ? 0 : 1,
            color: Color.white,
            action: { TripViewModel.shared.selectNextSegment() },
            label: { AnimatedChevronButtonLabel(isLeftFacing: false) }
        )
        .buttonStyle(.plain)
        .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        .glassEffect(.clear)
        .opacity(!rightVisible || isDragging ? 0 : 1)
        .offset(x: isDragging ? followX : (rightVisible ? visibleX : 0),
                y: isDragging ? followY : 0)
        .allowsHitTesting(rightVisible)
        .animation(.spring(duration: layout.animationDurations.medium), value: barDrag)
        .animation(.spring(duration: layout.animationDurations.slow), value: rightVisible)
    }
    
    private var contextBar: some View{
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
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 44))
        .contentShape(RoundedRectangle(cornerRadius: 44))
        .offset(isReview ? barDrag : .zero)
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if isReview { barDrag = value.translation }
                }
                .onEnded { _ in
                    if isReview {
                        barDrag = .zero
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
            color: Color.white,
            action: { mapViewModel.recenter() },
            label: { Image(systemName: mapViewModel.locationIconName) }
        )
        .glassEffect(.clear)
    }
    
    private var shareButton: some View {
        SystemControlButton(
            color: Color.white,
            action: { /* TODO */ },
            label: { Image(systemName: "square.and.arrow.up") }
        )
        .glassEffect(.clear)
    }
    
    private var settingsButton: some View {
        SystemControlButton(
            color: Color.white,
            action: { mainviewModel.settingsTapped() },
            label: { Image(systemName: "gearshape") }
        )
        .glassEffect(.clear)
    }
    
    private var summaryButton: some View {
        SystemControlButton(
            color: Color.white,
            action: { mainviewModel.summaryTapped() },
            label: { Image(systemName: "rectangle.stack") }
        )
        .glassEffect(.clear)
    }
}
