import SwiftUI

struct TitleBarView: View {
    @StateObject var viewModel = TBViewModel()
    @Environment(\.layout) private var layout
    
    var body: some View {
        VStack {
            GlassEffectContainer(spacing: 8) {
                ZStack {
                    backButton
                    extendPauseButton
                    titleBar
                }
            }
        }
    }
    
    private var backButton: some View {
        SystemControlButton(
            opacity: viewModel.isInMainState ? 0 : 1,
            color: Color.green,
            action: {
                viewModel.backButtonPressed()
                print("Back button pressed, from the title bar")
            },
            label: { Image(systemName: "chevron.left") }
        )
        .glassEffect(.clear)
        .disabled(viewModel.isInMainState)
        .allowsHitTesting(!viewModel.isInMainState)
        .offset(x: viewModel.isInMainState ? 0 : -layout.titleButtonOffset)
        .animation(.spring(duration: layout.animationDurations.slow, bounce: 0.35, blendDuration: 0.8), value: viewModel.isInMainState)
    }
    
    private var extendPauseButton: some View {
        SystemControlButton(
            opacity: viewModel.travelState == .paused ? 1 : 0,
            color: Color.orange,
            action: { viewModel.extendPauseButtonPressed() },
            label: { Image(systemName: "plus") }
        )
        .glassEffect(.clear)
        .disabled(viewModel.travelState != .paused)
        .allowsHitTesting(viewModel.travelState == .paused)
        .offset(x: viewModel.travelState == .paused ? layout.titleButtonOffset : 0)
        .animation(.spring(duration: layout.animationDurations.slow, bounce: 0.35, blendDuration: 0.8), value: viewModel.travelState == .paused)
    }
    
    private var titleBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.clear)
            
            ZStack {
                let start: CGFloat = 0.75
                let rawEnd = start + viewModel.sweepProgress
                
                if rawEnd <= 1.0 {
                    RoundedRectangle(cornerRadius: 50)
                        .trim(from: start, to: rawEnd)
                        .stroke(Color.orange.opacity(viewModel.travelState == .paused ? 0.9 : 0), lineWidth: 3)
                } else {
                    RoundedRectangle(cornerRadius: 50)
                        .trim(from: start, to: 1.0)
                        .stroke(Color.orange.opacity(viewModel.travelState == .paused ? 0.9 : 0), lineWidth: 3)
                    
                    RoundedRectangle(cornerRadius: 50)
                        .trim(from: 0.0, to: rawEnd - 1.0)
                        .stroke(Color.orange.opacity(viewModel.travelState == .paused ? 0.9 : 0), lineWidth: 3)
                }
            }
            
            HStack {
                Spacer()
                Text(viewModel.title)
                    .foregroundColor(AppTheme.Colors.primaryDark)
                    .font(.title)
                Spacer()
            }
        }
        .background(AppTheme.Colors.primaryDark.opacity(0.4))
        .frame(width: layout.titleWidth, height: layout.titleHeight)
        .glassEffect(.clear)
    }
}
