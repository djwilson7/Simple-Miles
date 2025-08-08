import SwiftUI

struct TripSortingView: View {
    @ObservedObject var viewModel: TripViewModel
    
    @State private var iconPosition: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var dateBarOffset: CGSize = .zero
    @State private var dateBarDragOffset: CGSize = .zero
    @State private var isDraggingDateBar: Bool = false
    @State private var dateBarOriginX: CGFloat = 0
    @State private var dateBarOriginY: CGFloat = 0
    @State private var currentDateBarX: CGFloat = 0
    @State private var currentDateBarY: CGFloat = 0
    @State private var personalChoiceBubbleScale: CGFloat = 1.0
    @State private var businessChoiceBubbleScale: CGFloat = 1.0
    
    var body: some View {
        GeometryReader { geo in
            GlassEffectContainer(spacing: 24) {
                VStack {
                    Spacer(minLength: geo.size.height * 0.3)
                    if (currentDateBarY < dateBarOriginY - 50) && !viewModel.unclassifiedSegments.isEmpty {
                        VStack {
                            sortRow(geo: geo)
                        }
                    }
                    
                    Spacer(minLength: geo.size.height * 0.3)
                    VStack(spacing: 20) {
                        if !viewModel.unclassifiedSegments.isEmpty {
                            statsRow(geo: geo)
                        }
                        
                        selectedTripRow(geo: geo)
                    }
                }
                .padding(20)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .all)
            .coordinateSpace(name: "TripSortingViewSpace")
        }
    }
    
    private func sortRow(geo: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            SortBubble(text: "Personal", size: 120)
                .padding(15)
                .scaleEffect(personalChoiceBubbleScale)
                .glassEffect(.clear)
            
            SortBubble(text: "Business", size: 120)
                .padding(15)
                .scaleEffect(businessChoiceBubbleScale)
                .glassEffect(.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: geo.size.height * 0.2)
    }
    
    private func statsRow(geo: GeometryProxy) -> some View {
        let barWidth = geo.size.width * 0.3
        let barHeight = geo.size.height * 0.05
        
        return HStack(spacing: 40) {
            Text(viewModel.currentDistance)
                .frame(width: barWidth, height: barHeight)
                .glassEffect()
            Text(viewModel.currentDuration)
                .frame(width: barWidth, height: barHeight)
                .glassEffect()
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
    
    private func selectedTripRow(geo: GeometryProxy) -> some View {
        let dateBarHeight = geo.size.height * 0.06
        let dateBarWidth = geo.size.width * 0.5
        
        return ZStack {
            if !viewModel.unclassifiedSegments.isEmpty {
                SystemControlButton(
                    icon: "chevron.left",
                    opacity: viewModel.currentTripIndex == 0 ? 0 : 1,
                    padding: 5,
                    color: Color.white,
                ) {
                    viewModel.selectPreviousSegment()
                }
                .glassEffect(.clear)
                .disabled(viewModel.currentTripIndex == 0)
                .allowsHitTesting(viewModel.currentTripIndex > 0)
                .offset(x: viewModel.currentTripIndex > 0 ? -150 : 0)
                .animation(.spring(duration: 0.8, bounce: 0.35, blendDuration: 0.8), value: viewModel.currentTripIndex > 0)
            }
            
            GeometryReader { barGeo in
                DateBar(geo: geo, payload: viewModel.currentStartDate, isDragging: isDraggingDateBar, hasTrips: !viewModel.unclassifiedSegments.isEmpty)
                    .offset(dateBarDragOffset)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                isDraggingDateBar = true
                                dateBarDragOffset = value.translation
                                currentDateBarX = dateBarOriginX + value.translation.width
                                currentDateBarY = dateBarOriginY + value.translation.height
                                updateChoiceBubbles()
                            }
                            .onEnded { _ in
                                if currentDateBarY < dateBarOriginY - 50 {
                                    if currentDateBarX < dateBarOriginX {
                                        viewModel.classifyCurrentSegment(newClassification: "personal")
                                    } else if currentDateBarX > dateBarOriginX {
                                        viewModel.classifyCurrentSegment(newClassification: "business")
                                    }
                                } else {
                                    if currentDateBarX < dateBarOriginX - 30 {
                                        viewModel.selectPreviousSegment()
                                    } else if currentDateBarX > dateBarOriginX + 30 {
                                        viewModel.selectNextSegment()
                                    }
                                }
                                isDraggingDateBar = false
                                withAnimation(.spring()) {
                                    dateBarDragOffset = .zero
                                    currentDateBarX = dateBarOriginX
                                    currentDateBarY = dateBarOriginY
                                }
                            }
                    )
                    .onAppear {
                        setInitalPoints(barGeo: barGeo)
                    }
                    .onChange(of: barGeo.size) { newSize, _ in
                        setInitalPoints(barGeo: barGeo)
                    }
            }
            .frame(width: dateBarWidth, height: dateBarHeight)
            
            if !viewModel.unclassifiedSegments.isEmpty {
                SystemControlButton(
                    icon: "chevron.right",
                    opacity: (viewModel.currentTripIndex < viewModel.unclassifiedSegments.count - 1) && !viewModel.unclassifiedSegments.isEmpty ? 1: 0,
                    padding: 5,
                    color: Color.white
                ) {
                    viewModel.selectNextSegment()
                }
                .glassEffect(.clear)
                .disabled(
                    viewModel.currentTripIndex == viewModel.unclassifiedSegments.count - 1 || viewModel.unclassifiedSegments.isEmpty
                )
                .allowsHitTesting((viewModel.currentTripIndex < viewModel.unclassifiedSegments.count - 1) && !viewModel.unclassifiedSegments.isEmpty)
                .offset(x: (viewModel.currentTripIndex < viewModel.unclassifiedSegments.count - 1) && !viewModel.unclassifiedSegments.isEmpty ? 150 : 0)
                .animation(.spring(duration: 0.8, bounce: 0.35, blendDuration: 0.8), value: (viewModel.currentTripIndex < viewModel.unclassifiedSegments.count - 1) && !viewModel.unclassifiedSegments.isEmpty)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func setInitalPoints(barGeo: GeometryProxy) {
        let frame = barGeo.frame(in: .named("TripSortingViewSpace"))
        dateBarOriginX = frame.midX
        dateBarOriginY = frame.midY
        currentDateBarX = frame.midX
        currentDateBarY = frame.midY
    }
    
    private func updateChoiceBubbles() {
        if currentDateBarY < dateBarOriginY - 50 {
            if currentDateBarX < dateBarOriginX {
                withAnimation(.spring()) {
                    personalChoiceBubbleScale = 1.1
                    businessChoiceBubbleScale = 0.2
                }
            } else if currentDateBarX > dateBarOriginX {
                withAnimation(.spring()) {
                    personalChoiceBubbleScale = 0.2
                    businessChoiceBubbleScale = 1.1
                }
            } else {
                withAnimation(.spring()) {
                    personalChoiceBubbleScale = 1.0
                    businessChoiceBubbleScale = 1.0
                }
            }
        } else {
            withAnimation(.spring()) {
                personalChoiceBubbleScale = 1.0
                businessChoiceBubbleScale = 1.0
            }
        }
    }
}

