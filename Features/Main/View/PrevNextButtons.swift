import SwiftUI

struct AnimatedChevronButtonLabel: View {
    @Environment(\.layout) private var layout
    let isLeftFacing: Bool
    @State private var progress: Double = 0
    private let chevronCount = 3
    private let animationDuration: Double = 3.0 // seconds for a full cycle
    private let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()

    init(isLeftFacing: Bool = true) {
        self.isLeftFacing = isLeftFacing
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<chevronCount, id: \.self) { index in
                // Phase offset for sequential animation
                let phaseOffset = isLeftFacing
                    ? Double(index) / Double(chevronCount)
                    : Double(chevronCount - 1 - index) / Double(chevronCount)
                let phase = (progress + phaseOffset).truncatingRemainder(dividingBy: 1)
                // Animate from 0 to 1 to 0
                let opacity = 0.2 + 0.8 * abs(sin(phase * .pi))
                Image(systemName: isLeftFacing ? "chevron.left" : "chevron.right")
                    .opacity(opacity)
            }
        }
        
        .contentShape(RoundedRectangle(cornerRadius: 44))
        .onReceive(timer) { _ in
            progress += 1.0 / (animationDuration * 60)
            if progress > 1 { progress -= 1 }
        }
        .onAppear { progress = 0 }
    }
}
