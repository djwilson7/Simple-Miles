import SwiftUI

struct DynamicContextBar<TripStatusContent: View, SettingsContent: View, ReviewContent: View>: View {
    @Environment(\.layout) private var layout
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel = DynamicContextBarViewModel.shared
    @State private var animatedHeight: CGFloat = 200
    @State private var animatedWidth: CGFloat = 200
    @State private var animateTask: Task<Void, Never>? = nil
    @State private var showContent = true
    @State private var targetSize: CGSize = .zero
    
    var minWidth: CGFloat { layout.width.pct(0.3) }
    var minHeight: CGFloat { max(40, layout.height.pct(0.05)) }
        
    let tripStatusContent: () -> TripStatusContent
    let settingsContent: () -> SettingsContent
    let reviewContent: () -> ReviewContent
    
    var body: some View {
        ZStack {
            if !showContent {
                ProgressView()
            }
            if showContent {
                switch viewModel.mainState {
                case .main:
                    tripStatusContent()
                        .appPadding(.all, layout.spacing.m)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { updateSize(from: geo.size) }
                                    .onChange(of: geo.size) { _, newSize in updateSize(from: newSize) }
                            }
                        )
                case .settings:
                    ScrollView {
                        settingsContent()
                            .appPadding(.all, layout.spacing.m)
                            .overlay(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear { updateSize(from: geo.size) }
                                        .onChange(of: geo.size) { _, newSize in updateSize(from: newSize) }
                                }
                            )
                    }
                case .review:
                    reviewContent()
                        .appPadding(.all, layout.spacing.m)
                        .overlay(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear { updateSize(from: geo.size) }
                                    .onChange(of: geo.size) { _, newSize in updateSize(from: newSize) }
                            }
                        )
                }
            }
        }
        .id(colorScheme)
        .frame(width: animatedWidth, height: animatedHeight, alignment: .center)
        .onChange(of: viewModel.mainState) { _, _ in
            runContentTransitionAnimation()
        }
        .onChange(of: colorScheme) { _, _ in
            runContentTransitionAnimation()
        }
        .onAppear {
            if targetSize != .zero {
                animatedHeight = targetSize.height
                animatedWidth = targetSize.width
            }
        }
        .onDisappear { animateTask?.cancel() }
    }
    // MARK: - Private helpers
    private func updateSize(from size: CGSize) {
        targetSize = size
        if showContent {
            animatedWidth = size.width
            animatedHeight = size.height
        } else {
            if animatedWidth != size.width {
                animatedWidth = size.width
            }
            if animatedHeight != size.height {
                animatedHeight = size.height
            }
        }
    }
    
    private func runContentTransitionAnimation() {
        animateTask?.cancel()
        animateTask = Task {
            await MainActor.run {
                showContent = false
                withAnimation(.easeInOut(duration: layout.animationDurations.fast)) {
                    animatedHeight = minHeight
                    animatedWidth = minWidth
                }
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: layout.animationDurations.medium)) {
                    animatedHeight = targetSize.height
                    animatedWidth = targetSize.width
                }
            }
            try? await Task.sleep(nanoseconds: UInt64(layout.animationDurations.medium * 1_000_000_000))
            await MainActor.run {
                showContent = true
            }
        }
    }
}
