import SwiftUI
import MapKit

struct MainView: View {
    @ObservedObject var mainviewModel: MainViewModel
    @ObservedObject var mapViewModel: MapViewModel
    @State private var barDrag: CGSize = .zero
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
        let followX = (isReview && !leftVisible) ? barDrag.width : 0
        let followY = (isReview && !leftVisible) ? barDrag.height : 0
        let visibleX = -layout.width.pct(0.4)
        return SystemControlButton( //Left Button
            opacity: leftVisible ? 1: 0,
            color: Color.white,
            action: { TripViewModel.shared.selectPreviousSegment() },
            label: { AnimatedChevronButtonLabel(isLeftFacing: true) }
        )
        .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        .buttonStyle(.plain)
        .glassEffect(.clear)
        .opacity(leftVisible ? 1: 0)
        .offset(x: leftVisible ? visibleX : followX, y: leftVisible ? 0 : followY)
        .allowsHitTesting(leftVisible)
        .animation(.spring(duration: 0.5), value: leftVisible)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: barDrag)
    }
    
    private var nextButton: some View {
        let rightVisible = isReview && canGoNext
        let followX = (isReview && !rightVisible) ? barDrag.width : 0
        let followY = (isReview && !rightVisible) ? barDrag.height : 0
        let visibleX = layout.width.pct(0.4)
        return SystemControlButton(
            opacity: rightVisible ? 1: 0,
            color: Color.white,
            action: { TripViewModel.shared.selectNextSegment() },
            label: { AnimatedChevronButtonLabel(isLeftFacing: false) }
        )
        .buttonStyle(.plain)
        .frame(width: layout.buttonWidth, height: layout.buttonHeight)
        .glassEffect(.clear)
        .opacity(rightVisible ? 1 : 0)
        .offset(x: rightVisible ? visibleX : followX, y: rightVisible ? 0 : followY)
        .allowsHitTesting(rightVisible)
        .animation(.spring(duration: 0.5), value: rightVisible)
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: barDrag)
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
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.65)) {
                            barDrag = .zero
                        }
                    }
                }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.65), value: barDrag)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 10) {
            settingsButton
            shareButton
            summaryButton
            recenterButton
        }
        .padding(.trailing, 5)
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
