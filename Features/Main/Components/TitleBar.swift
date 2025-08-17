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
            color: AppTheme.Colors.primaryText,
            action: {
                viewModel.backButtonPressed()
            },
            label: { Image(systemName: "chevron.left") }
        )
        .disabled(viewModel.isInMainState)
        .allowsHitTesting(!viewModel.isInMainState)
        .offset(x: viewModel.isInMainState ? 0 : -layout.titleButtonOffset)
        .animation(.spring(duration: layout.animationDurations.slow, bounce: 0.35, blendDuration: 0.8), value: viewModel.isInMainState)
    }
    
    private var extendPauseButton: some View {
        SystemControlButton(
            opacity: viewModel.travelState == .paused ? 1 : 0,
            color: .orange,
            action: { viewModel.extendPauseButtonPressed() },
            label: { Image(systemName: "plus") }
        )
        .disabled(viewModel.travelState != .paused)
        .allowsHitTesting(viewModel.travelState == .paused)
        .offset(x: viewModel.travelState == .paused ? layout.titleButtonOffset : 0)
        .animation(.spring(duration: layout.animationDurations.slow, bounce: 0.35, blendDuration: 0.8), value: viewModel.travelState == .paused)
    }
    
    private var titleBar: some View {
        ZStack {
            RoundedRectangle(cornerRadius: layout.radii.pill)
                .fill(Color.clear)
            
            ZStack {
                let start: CGFloat = 0.75
                let rawEnd = start + viewModel.sweepProgress
                
                if rawEnd <= 1.0 {
                    RoundedRectangle(cornerRadius: layout.radii.pill)
                        .trim(from: start, to: rawEnd)
                        .stroke(Color.orange.opacity(viewModel.travelState == .paused ? 0.9 : 0), lineWidth: 3)
                } else {
                    RoundedRectangle(cornerRadius: layout.radii.pill)
                        .trim(from: start, to: 1.0)
                        .stroke(Color.orange.opacity(viewModel.travelState == .paused ? 0.9 : 0), lineWidth: 3)
                    
                    RoundedRectangle(cornerRadius: layout.radii.pill)
                        .trim(from: 0.0, to: rawEnd - 1.0)
                        .stroke(Color.orange.opacity(viewModel.travelState == .paused ? 0.9 : 0), lineWidth: 3)
                }
            }
            
            HStack {
                Spacer()
                Text(viewModel.title)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .font(.headline).bold().monospaced()
                Spacer()
            }
        }
        .frame(width: layout.elementWidth, height: layout.titleHeight)
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .glassEffect()
    }
}
