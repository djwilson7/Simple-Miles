import SwiftUI

struct TripView: View {
    @ObservedObject var viewModel: TripViewModel
    @State private var topCardIndex = 0
    @GestureState private var dragOffset = CGSize.zero
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(viewModel.allSegments.indices, id: \.self) { index in
                    let delta = index - topCardIndex
                    if abs(delta) <= 1 {
                        StackedTripCard(
                            segment: viewModel.allSegments[index],
                            delta: delta,
                            isTopCard: delta == 0,
                            onAdvance: {
                                topCardIndex = min(topCardIndex + 1, viewModel.allSegments.count - 1)
                            },
                            onRetreat: {
                                topCardIndex = max(topCardIndex - 1, 0)
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
        }
        .padding(5)
        .onChange(of: topCardIndex) {
            viewModel.updateSelectedPath(index: topCardIndex)
        }
    }
}

private struct StackedTripCard: View {
    let segment: TripSegment
    let delta: Int
    let isTopCard: Bool
    let onAdvance: () -> Void
    let onRetreat: () -> Void
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        TripCardView(segment: segment)
            .scaleEffect(delta == 0 ? 1.0 : 0.95)
            .glassEffect(isTopCard ? .regular : .clear, in: RoundedRectangle(cornerRadius: 16))
            .offset(y: CGFloat(delta) * 30 + (delta == 0 ? dragOffset.height : 0))
            .zIndex(Double(2 - abs(delta)))
            .padding(.horizontal, 8)
            .gesture(
                isTopCard ?
                DragGesture(minimumDistance: 20)
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                : nil
            )
            .onChange(of: dragOffset) {
                if dragOffset.height < -20 {
                    withAnimation(.spring()) {
                        onAdvance()
                    }
                } else if dragOffset.height > 20 {
                    withAnimation(.spring()) {
                        onRetreat()
                    }
                }
            }
    }
}
