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
            let barHeight = geo.size.height * 0.05
            let dateBarHeight = geo.size.height * 0.06
            let barWidth = geo.size.width * 0.3
            let dateBarWidth = geo.size.width * 0.5
            let frame = geo.frame(in: .global)
            let dateBarCenter = CGPoint(x: frame.midX, y: frame.midY)
            
            GlassEffectContainer(spacing: 24) {
                VStack {
                    sortRow(geo: geo)
                    
                    statsRow(
                        barWidth: barWidth,
                        barHeight: barHeight
                    )
                    
                    selectedTripRow(
                        barWidth: barWidth,
                        dateBarWidth: dateBarWidth,
                        dateBarHeight: dateBarHeight,
                        dateBarCenter: dateBarCenter
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea(edges: .all)
        }
    }
    
    private func sortRow(geo: GeometryProxy) -> some View {
        HStack {
            Spacer()
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
            Spacer()
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
            Spacer()
        }
    }
    
    private func statsRow(barWidth: CGFloat, barHeight: CGFloat) -> some View {
        HStack {
            Spacer()
            Text("Distance")
                .frame(width: barWidth, height: barHeight)
                .glassEffect(.clear)
            Spacer()
            Text("Duration")
                .frame(width: barWidth, height: barHeight)
                .glassEffect(.clear)
            Spacer()
        }
        .font(.subheadline)
        .frame(maxWidth: .infinity)
    }
    
    private func selectedTripRow(barWidth: CGFloat, dateBarWidth: CGFloat, dateBarHeight: CGFloat, dateBarCenter: CGPoint) -> some View {
        HStack {
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
