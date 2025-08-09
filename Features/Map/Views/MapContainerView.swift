import SwiftUI
import MapKit


struct MapContainerView: View {
    @ObservedObject var viewModel: MapContainerViewModel
    @ObservedObject var mapViewModel: MapViewModel
    
    @State private var showSettingsModal = false
    @State private var statusBarHeight: CGFloat = 0
    @State private var showTripModal = false
    @State private var isInSettings = false
    
    private var isViewingState: Bool {
        viewModel.tripViewModel.isReviewing || isInSettings
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(viewModel: mapViewModel)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                titleContainer
                    .padding(.top, 20)
                
                Spacer()
            }
            
            // Toast overlay (centered above trip time bar)
            if let toast = ToastManager.shared.currentToast {
                VStack {
                    Spacer()
                    Text(toast.body)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 140)
                        .transition(.opacity)
                        .animation(.easeInOut, value: toast)
                }
            }
            
            if !(viewModel.tripViewModel.isReviewing || isInSettings) {
                statusBar
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear {
                                    statusBarHeight = geo.size.height
                                }
                                .onChange(of: geo.size.height) { _, newValue in
                                    statusBarHeight = newValue
                                }
                        }
                    )
            }
            
            if viewModel.tripViewModel.isReviewing {
                TripSortingView(viewModel: viewModel.tripViewModel)
            }
        }
        
        .overlay(alignment: .bottomTrailing) {
            if !(viewModel.tripViewModel.isReviewing || isInSettings) {
                controlButtons
                    .padding(.trailing, 20)
                    .padding(.bottom, statusBarHeight + 20)
            }
        }
        
        .onAppear {
            viewModel.onSettings = {
                showSettingsModal = true
                isInSettings = true
            }
        }
        
        .overlay(settingsOverlay)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 10) {
            settingsButton
            shareButton
            summaryButton
            recenterButton
        }
    }
    
    private var titleContainer: some View {
        GeometryReader { geo in
            GlassEffectContainer(spacing: 8) {
                ZStack {
                    backButton
                    extendPauseButton
                    titleBar(geo: geo)
                }
            }
            .position(x: geo.size.width / 2, y: 20)
        }
    }
    
    private var backButton: some View {
        SystemControlButton(
            icon: "chevron.left",
            opacity: isViewingState ? 1: 0,
            color: Color.green
        ) {
            viewModel.tripViewModel.isReviewing = false
            isInSettings = false
            showSettingsModal = false
        }
        .glassEffect(.clear)
        .disabled(!isViewingState)
        .allowsHitTesting(isViewingState)
        .offset(x: isViewingState ? -150 : 0)
        .animation(.spring(duration: 0.8, bounce: 0.35, blendDuration: 0.8), value: isViewingState)
    }
    
    private var extendPauseButton: some View {
        SystemControlButton(
            icon: "plus",
            opacity: viewModel.tripState == .paused ? 1 : 0,
            color: Color.orange
        ) {
            viewModel.extendPauseTapped()
        }
        .glassEffect(.clear)
        .disabled(viewModel.tripState != .paused)
        .allowsHitTesting(viewModel.tripState == .paused)
        .offset(x: viewModel.tripState == .paused ? 150 : 0)
        .animation(.spring(duration: 0.8, bounce: 0.35, blendDuration: 0.8), value: viewModel.tripState == .paused)
    }
    
    private func titleBar(geo: GeometryProxy) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.clear)
            
            ZStack {
                let start: CGFloat = 0.75
                let rawEnd = start + viewModel.sweepProgress
                
                if rawEnd <= 1.0 {
                    RoundedRectangle(cornerRadius: 50)
                        .trim(from: start, to: rawEnd)
                        .stroke(Color.orange.opacity(viewModel.tripState == .paused ? 0.9 : 0), lineWidth: 3)
                } else {
                    RoundedRectangle(cornerRadius: 50)
                        .trim(from: start, to: 1.0)
                        .stroke(Color.orange.opacity(viewModel.tripState == .paused ? 0.9 : 0), lineWidth: 3)
                    
                    RoundedRectangle(cornerRadius: 50)
                        .trim(from: 0.0, to: rawEnd - 1.0)
                        .stroke(Color.orange.opacity(viewModel.tripState == .paused ? 0.9 : 0), lineWidth: 3)
                }
            }
            
            HStack {
                Spacer()
                HStack(spacing: 4) {
                    if viewModel.tripViewModel.isReviewing {
                        Text("Trip Sorting")
                            .foregroundColor(.primary)
                    } else if viewModel.tripState == .paused {
                        Text("Ending Trip In: ")
                            .foregroundColor(.primary)
                        
                        Text(viewModel.pauseCountdownFormatted)
                            .foregroundColor(.orange)
                    } else {
                        Text("Simple Miles")
                            .foregroundColor(.primary)
                    }
                }
                .font(.headline)
                Spacer()
            }
            .padding(.vertical, 10)
        }
        .frame(width: geo.size.width * 0.5, height: 44)
        .glassEffect(.clear)
    }
    
    private var statusBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.tripStateText)
                        .font(.body)
                        .foregroundColor(viewModel.tripStateColor)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))
                
                VStack(spacing: 2) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f miles", viewModel.tripDistanceCommittedMiles))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(String(format: "%.1f miles", viewModel.tripDistanceLiveMiles))
                        .font(.caption2)
                        .foregroundColor(
                            viewModel.tripState == .paused ? .orange :
                                viewModel.tripState == .traveling ? .green :
                                viewModel.tripDistanceLiveMiles > 0 ? .green : .gray
                        )
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))
                
                VStack(spacing: 2) {
                    Text("Trip Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedTime(viewModel.tripDurationCommitted))
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Text(formattedTime(viewModel.tripDurationLive))
                        .font(.caption2)
                        .foregroundColor(
                            viewModel.tripState == .paused ? .orange :
                                viewModel.tripState == .traveling ? .green :
                                viewModel.tripDurationLive > 0 ? .green : .gray
                        )
                }
                .frame(maxWidth: .infinity)
                
            }
            .padding(.vertical)
            .padding(.horizontal)
            .frame(width: geo.size.width * 0.9, alignment: .center)
            .glassEffect(.clear)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
        .frame(height: 60)
    }
    
    private var recenterButton: some View {
        SystemControlButton(
            icon: mapViewModel.locationIconName,
            padding: 10,
            color: Color.white
        ) {
            mapViewModel.recenter()
        }
        .glassEffect(.clear)
    }
    
    private var shareButton: some View {
        SystemControlButton(
            icon: "square.and.arrow.up",
            padding: 10,
            color: Color.white
        ) {
            viewModel.shareTapped()
        }
        .glassEffect(.clear)
    }
    
    private var settingsButton: some View {
        SystemControlButton(
            icon: "gearshape",
            padding: 10,
            color: Color.white
        ) {
            viewModel.settingsTapped()
        }
        .glassEffect(.clear)
    }
    
    private var summaryButton: some View {
        SystemControlButton(
            icon: "rectangle.stack",
            padding: 10,
            color: Color.white
        ) {
            viewModel.tripViewModel.isReviewing = true
            viewModel.summaryTapped()
        }
        .glassEffect(.clear)
    }
    
    private var settingsOverlay: some View {
        GeometryReader { geo in
            Group {
                if showSettingsModal {
                    ZStack {
                        VStack(spacing: 0) {
                            HStack {
                                Spacer().frame(width: 4)
                                Text("Settings")
                                    .font(.title)
                                    .bold()
                                Spacer()
                                Button(action: {
                                    showSettingsModal = false
                                    isInSettings = false
                                }) {
                                    Image(systemName: "xmark")
                                        .font(.title2)
                                        .padding(8)
                                }
                                .buttonStyle(.plain)
                                Spacer().frame(width: 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 18)
                            .padding(.bottom, 6)
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0.14), Color.clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .frame(height: 12)
                                .offset(y: 10),
                                alignment: .bottom
                            )
                            ScrollView {
                                SettingsView(isPresented: $showSettingsModal)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .frame(
                            width: geo.size.width * 0.9,
                            height: geo.size.height * 0.8
                        )
                        
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28))
                        .shadow(color: Color.black.opacity(0.45), radius: 32, x: 0, y: 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}

private func formattedTime(_ interval: TimeInterval) -> String {
    let minutes = Int(interval) / 60
    let seconds = Int(interval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
}

struct GlassButtonStyle: ButtonStyle {
    var borderOpacity: Double = 1.0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                Circle().fill(.ultraThinMaterial)
            )
            .overlay(
                Circle().stroke(Color.white.opacity(borderOpacity), lineWidth: 2)
            )
    }
}

