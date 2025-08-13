import SwiftUI

struct DynamicContextBar<TripStatusContent: View, SettingsContent: View, ReviewContent: View>: View {
    @Environment(\.layout) private var layout
    @ObservedObject var viewModel = DynamicContextBarViewModel.shared
    @State private var animatedHeight: CGFloat = 200
    @State private var animatedWidth: CGFloat = 200
    @State private var animateTask: Task<Void, Never>? = nil
    @State private var showContent = true
    @State private var targetSize: CGSize = .zero
    
    var minWidth: CGFloat { layout.width.pct(0.3) }
    var minHeight: CGFloat { layout.height.pct(0.05) }
        
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
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        targetSize = geo.size
                                        if animatedWidth != geo.size.width {
                                            animatedWidth = geo.size.width
                                        }
                                        if animatedHeight != geo.size.height {
                                            animatedHeight = geo.size.height
                                        }
                                    }
                                    .onChange(of: geo.size) { _, newSize in
                                        targetSize = newSize
                                        if showContent {
                                            animatedWidth = newSize.width
                                            animatedHeight = newSize.height
                                        }
                                    }
                            }
                        )
                case .settings:
                    ScrollView {
                        settingsContent()
                            .appPadding(.all, layout.spacing.m)
                            .background(
                                GeometryReader { geo in
                                    Color.clear
                                        .onAppear {
                                            targetSize = geo.size
                                            if animatedWidth != geo.size.width {
                                                animatedWidth = geo.size.width
                                            }
                                            if animatedHeight != geo.size.height {
                                                animatedHeight = geo.size.height
                                            }
                                        }
                                        .onChange(of: geo.size) { _, newSize in
                                            targetSize = newSize
                                            if showContent {
                                                animatedWidth = newSize.width
                                                animatedHeight = newSize.height
                                            }
                                        }
                                }
                            )
                    }
                case .review:
                    reviewContent()
                        .appPadding(.all, layout.spacing.m)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        targetSize = geo.size
                                        if animatedWidth != geo.size.width {
                                            animatedWidth = geo.size.width
                                        }
                                        if animatedHeight != geo.size.height {
                                            animatedHeight = geo.size.height
                                        }
                                    }
                                    .onChange(of: geo.size) { _, newSize in
                                        targetSize = newSize
                                        if showContent {
                                            animatedWidth = newSize.width
                                            animatedHeight = newSize.height
                                        }
                                    }
                            }
                        )
                }
            }
        }
        .frame(width: animatedWidth, height: animatedHeight, alignment: .center)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .onChange(of: viewModel.mainState) { oldValue, newValue in
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
        .onAppear {
            if targetSize != .zero {
                animatedHeight = targetSize.height
                animatedWidth = targetSize.width
            }
        }
        .onDisappear { animateTask?.cancel() }
    }
}
