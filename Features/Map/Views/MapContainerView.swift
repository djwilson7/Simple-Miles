import SwiftUI
import MapKit

struct MapContainerView: View {
    @ObservedObject var viewModel: MapContainerViewModel
    @ObservedObject var mapViewModel: MapViewModel
    
    @State private var showSettingsModal = false
    @State private var statusBarHeight: CGFloat = 0
    @State private var showTripModal = false

    var body: some View {
        ZStack(alignment: .bottom) {
            MapView(viewModel: mapViewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleBar
                    .padding(.top, 12)

                if viewModel.tripState == .paused {
                    extendPauseButton
                }

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

            if !viewModel.tripViewModel.isReviewing {
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
        }
        .overlay(alignment: .bottom) {
            if viewModel.tripViewModel.isReviewing {
                VStack(spacing: 20) {
                    TripView(viewModel: viewModel.tripViewModel)
                        .padding(.horizontal)

                    Button(action: {
                        viewModel.tripViewModel.isReviewing = false
                    }) {
                        Text("Sort Trips Later")
                            .font(.footnote.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.blue)
                                    .shadow(radius: 4)
                            )
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if !viewModel.tripViewModel.isReviewing {
                controlButtons
                    .padding(.trailing, 20)
                    .padding(.bottom, statusBarHeight + 20)
            }
        }
        .onAppear {
            viewModel.onSettings = {
                showSettingsModal = true
            }
        }
        .overlay(settingsOverlay)
        .overlay(tripOverlay)
    }

    private var controlButtons: some View {
        VStack(spacing: 10) {
            settingsButton
            shareButton
            summaryButton
            recenterButton
        }
    }

    private var titleBar: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)

                ZStack {
                    let start: CGFloat = 0.75
                    let rawEnd = start + viewModel.sweepProgress

                    if rawEnd <= 1.0 {
                        RoundedRectangle(cornerRadius: 16)
                            .trim(from: start, to: rawEnd)
                            .stroke(Color.orange.opacity(viewModel.tripState == .paused ? 0.9 : 0), lineWidth: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .trim(from: start, to: 1.0)
                            .stroke(Color.orange.opacity(viewModel.tripState == .paused ? 0.9 : 0), lineWidth: 3)

                        RoundedRectangle(cornerRadius: 16)
                            .trim(from: 0.0, to: rawEnd - 1.0)
                            .stroke(Color.orange.opacity(viewModel.tripState == .paused ? 0.9 : 0), lineWidth: 3)
                    }
                }

                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        if viewModel.tripViewModel.isReviewing {
                            Text("Trip Sorting").foregroundColor(.primary)
                        } else if viewModel.tripState == .paused {
                            Text("Ending Trip In: ")
                                .foregroundColor(.primary)
                            Text(viewModel.pauseCountdownFormatted)
                                .foregroundColor(.orange)
                        } else {
                            Text("Simple Miles").foregroundColor(.primary)
                        }
                    }
                    .font(.headline)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .frame(height: geo.size.height)
        }
        .frame(height: 44)
        .padding(.horizontal)
    }

    private var statusBar: some View {
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
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private var recenterButton: some View {
        Button(action: {
            viewModel.recenterTapped()
            mapViewModel.recenter()
        }) {
            Image(systemName: mapViewModel.locationIconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }

    private var shareButton: some View {
        Button(action: {
            viewModel.shareTapped()
        }) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }

    private var settingsButton: some View {
        Button {
            viewModel.settingsTapped()
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }

    private var summaryButton: some View {
        Button(action: {
            viewModel.tripViewModel.isReviewing = true
            viewModel.summaryTapped()
        }) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding(12)
                .background(.blue)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }

    private var extendPauseButton: some View {
        Button(action: {
            viewModel.extendPauseTapped()
        }) {
            Text("Extend Pause")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 44)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 44)
                        .stroke(Color.orange, lineWidth: 1.5)
                )
        }
        .padding(.top, 8)
    }
    
    private var settingsOverlay: some View {
        GeometryReader { geo in
            Group {
                if showSettingsModal {
                    SettingsView(isPresented: $showSettingsModal)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .frame(
                            maxWidth: geo.size.width * 0.9,
                            maxHeight: geo.size.height * 0.9
                        )
                }
            }
        }
    }

    private var tripOverlay: some View {
        GeometryReader { geo in
            Group {
                if showTripModal {
                    TripView(viewModel: viewModel.tripViewModel)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .frame(
                            maxWidth: geo.size.width * 0.9,
                            maxHeight: geo.size.height * 0.9
                        )
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
