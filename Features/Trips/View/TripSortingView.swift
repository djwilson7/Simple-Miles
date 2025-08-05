import SwiftUI

struct TripSortingView: View {
    @State private var iconPosition: CGPoint = .zero
    @State private var dragOffset: CGSize = .zero
    @State private var dateBarOffset: CGSize = .zero
    @State private var dateBarDragOffset: CGSize = .zero
    @State private var isDraggingDateBar: Bool = false
    
    @State private var personalBubbleCenter: CGPoint? = nil
    @State private var businessBubbleCenter: CGPoint? = nil
    
    enum DateBarAnchor {
        case none, personal, business
    }
    @State private var dateBarAnchor: DateBarAnchor = .none
    
    var body: some View {
        GeometryReader { geo in
            GlassEffectContainer(spacing: 24) {
                VStack {
                    Spacer(minLength: geo.size.height * 0.3)
                    VStack {
                        sortRow(geo: geo)
                    }
                    Spacer(minLength: geo.size.height * 0.3)
                    VStack(spacing: 20) {
                        statsRow(geo: geo)
                        
                        selectedTripRow(geo: geo)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .all)
        }
    }
    
    private func sortRow(geo: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            SortBubble(text: "Personal")
                .onAppear {
                    let frame = geo.frame(in: .global)
                    personalBubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                }
                .onChange(of: geo.size) { _, _ in
                    let frame = geo.frame(in: .global)
                    personalBubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                }
                .onChange(of: geo.frame(in: .global)) { _, _ in
                    let frame = geo.frame(in: .global)
                    personalBubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                }
            SortBubble(text: "Business")
                .onAppear {
                    let frame = geo.frame(in: .global)
                    businessBubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                }
                .onChange(of: geo.size) { _, _ in
                    let frame = geo.frame(in: .global)
                    businessBubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                }
                .onChange(of: geo.frame(in: .global)) { _, _ in
                    let frame = geo.frame(in: .global)
                    businessBubbleCenter = CGPoint(x: frame.midX, y: frame.midY)
                }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statsRow(geo: GeometryProxy) -> some View {
        let barWidth = geo.size.width * 0.3
        let barHeight = geo.size.height * 0.05

        return HStack(spacing: 40) {
            Text("Distance")
                .frame(width: barWidth, height: barHeight)
                .glassEffect(.clear)
            Text("Duration")
                .frame(width: barWidth, height: barHeight)
                .glassEffect(.clear)
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
    
    private func selectedTripRow(geo: GeometryProxy) -> some View {
        let dateBarHeight = geo.size.height * 0.06
        let dateBarWidth = geo.size.width * 0.5
        let dateBarCenter = CGPoint(x: geo.frame(in: .global).midX, y: geo.frame(in: .global).midY)
        let barWidth = geo.size.width * 0.3

        return HStack(spacing: 40) {
            Text(".")
                .frame(width: barWidth / 3, height: dateBarHeight)
                .glassEffect(.clear)
            
            DateBar(width: dateBarWidth, payload: "Jun 31st 2025 1:23pm")
                .scaleEffect(isDraggingDateBar ? 0.5 : 1.0)
                .offset(dateBarAnchorOffset(currentCenter: dateBarCenter))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dateBarDragOffset = value.translation
                            isDraggingDateBar = true
                        }
                        .onEnded { _ in
                            isDraggingDateBar = false
                            // Calculate distances and update anchor
                            let threshold: CGFloat = 60
                            if let personalCenter = personalBubbleCenter,
                               distance(from: dateBarCenter, to: CGPoint(x: personalCenter.x + dateBarDragOffset.width, y: personalCenter.y + 0)) < threshold {
                                dateBarAnchor = .personal
                                withAnimation(.spring()) {
                                    dateBarDragOffset = .zero
                                }
                            } else if let businessCenter = businessBubbleCenter,
                                      distance(from: dateBarCenter, to: CGPoint(x: businessCenter.x + dateBarDragOffset.width, y: businessCenter.y + 0)) < threshold {
                                dateBarAnchor = .business
                                withAnimation(.spring()) {
                                    dateBarDragOffset = .zero
                                }
                            } else {
                                dateBarAnchor = .none
                                withAnimation(.spring()) {
                                    dateBarDragOffset = .zero
                                }
                            }
                        }
                )
                .frame(width: dateBarWidth, height: dateBarHeight)
            
            Text(".")
                .frame(width: barWidth / 3, height: dateBarHeight)
                .glassEffect(.clear)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
    }
    
    func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(pow(from.x - to.x, 2) + pow(from.y - to.y, 2))
    }
    
    func dateBarAnchorOffset(currentCenter: CGPoint) -> CGSize {
        guard let personalCenter = personalBubbleCenter,
              let businessCenter = businessBubbleCenter else {
            return dateBarDragOffset
        }
        
        switch dateBarAnchor {
        case .none:
            return dateBarDragOffset
        case .personal:
            let dx = personalCenter.x - currentCenter.x
            let dy = personalCenter.y - currentCenter.y
            return CGSize(width: dx, height: dy)
        case .business:
            let dx = businessCenter.x - currentCenter.x
            let dy = businessCenter.y - currentCenter.y
            return CGSize(width: dx, height: dy)
        }
    }
}

#Preview {
    TripSortingView()
}
