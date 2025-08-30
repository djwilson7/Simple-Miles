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
            isVisible: !viewModel.isInMainState,
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
            isVisible: viewModel.travelState == .paused,
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

            TimelineView(.animation) { _ in
                let start: CGFloat = 0.75
                let isPaused = viewModel.travelState == .paused
                if isPaused, let snap = viewModel.pauseSnapshot {
                    let remaining = max(0, snap.end.timeIntervalSinceNow)
                    let total = max(0.001, snap.total) // avoid divide-by-zero
                    let progress = max(0, min(1, 1 - (remaining / total)))
                    let rawEnd = start + CGFloat(progress)

                    ZStack {
                        if rawEnd <= 1.0 {
                            RoundedRectangle(cornerRadius: layout.radii.pill)
                                .trim(from: start, to: rawEnd)
                                .stroke(Color.orange.opacity(0.9), lineWidth: 3)
                        } else {
                            RoundedRectangle(cornerRadius: layout.radii.pill)
                                .trim(from: start, to: 1.0)
                                .stroke(Color.orange.opacity(0.9), lineWidth: 3)

                            RoundedRectangle(cornerRadius: layout.radii.pill)
                                .trim(from: 0.0, to: rawEnd - 1.0)
                                .stroke(Color.orange.opacity(0.9), lineWidth: 3)
                        }
                    }
                }
            }

            TimelineView(.animation) { _ in
                HStack {
                    Spacer()
                    if viewModel.travelState == .paused && viewModel.state == .main, let snap = viewModel.pauseSnapshot {
                        let remaining = max(0, snap.end.timeIntervalSinceNow)
                        Text(TimeUtility.formatter(remaining))
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .uiText(.title)
                            .id(snap.id)
                    } else {
                        Text(viewModel.title)
                            .foregroundColor(AppTheme.Colors.primaryText)
                            .uiText(.title)
                    }
                    Spacer()
                }
                .uiBlock(.title)
            }
        }
        .frame(width: layout.elementWidth, height: layout.titleHeight)
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .glassEffect(.clear)
        .onTapGesture {
            TripSubMenuViewModel.shared.isVisible = false
        }
    }
}
