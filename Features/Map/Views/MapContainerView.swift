import SwiftUI
import MapKit

struct MapContainerView: View {
    @StateObject var viewModel: MapContainerViewModel
    @StateObject private var mapViewModel = MapViewModel()

    @State private var statusBarHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            MainMapView(viewModel: mapViewModel)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                titleBar
                    .padding(.top, 12)
                Spacer()
            }

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
        .overlay(alignment: .bottomTrailing) {
            VStack(spacing: 10) {
                settingsButton
                shareButton
                summaryButton
                recenterButton
            }
            .padding(.trailing, 20)
            .padding(.bottom, statusBarHeight + 20)
        }
        .onAppear {
            viewModel.onRecenter = {
                mapViewModel.recenter()
            }
            mapViewModel.requestLocationPermission()
            mapViewModel.startTracking()
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
                            .stroke(Color.orange.opacity(viewModel.isPaused ? 0.9 : 0), lineWidth: 3)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .trim(from: start, to: 1.0)
                            .stroke(Color.orange.opacity(viewModel.isPaused ? 0.9 : 0), lineWidth: 3)

                        RoundedRectangle(cornerRadius: 16)
                            .trim(from: 0.0, to: rawEnd - 1.0)
                            .stroke(Color.orange.opacity(viewModel.isPaused ? 0.9 : 0), lineWidth: 3)
                    }
                }

                HStack {
                    Spacer()
                    (
                        viewModel.isPaused
                        ? Text("Ending Trip In: ")
                            .foregroundColor(.primary)
                            + Text(viewModel.pauseCountdownFormatted)
                            .foregroundColor(.orange)
                        : Text("Simple Miles")
                            .foregroundColor(.primary)
                    )
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
            VStack(alignment: .center, spacing: 2) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.tripStatusText)
                    .font(.body)
                    .foregroundColor(viewModel.tripStatusColor)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 1, height: 28)
                .padding(.vertical, 4)

            VStack(alignment: .center, spacing: 2) {
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.tripDistance)
                    .font(.body)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 1, height: 28)
                .padding(.vertical, 4)

            VStack(alignment: .center, spacing: 2) {
                Text("Trip Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.tripDuration)
                    .font(.body)
                    .foregroundColor(.primary)
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
        }) {
            Image(systemName: "location.fill")
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
        Button(action: {
            viewModel.settingsTapped()
        }) {
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
}
