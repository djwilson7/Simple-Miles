import MapKit
import SwiftUI
import UIKit

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        ZStack {
            Map(
                position: $viewModel.cameraPosition,
                interactionModes: .all
            ) {
                if !(MainStateDriver.shared.mainState == .review) {
                    // Committed (stored) path
                    if !viewModel.commitedTracePath.isEmpty {
                        let path = viewModel.commitedTracePath

                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.1),
                                lineWidth: 12
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.2),
                                lineWidth: 11
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.3),
                                lineWidth: 10
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.4),
                                lineWidth: 9
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.5),
                                lineWidth: 8
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.6),
                                lineWidth: 7
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.7),
                                lineWidth: 6
                            )
                        MapPolyline(coordinates: path)
                            .stroke(AppTheme.Colors.primaryPath, lineWidth: 5)
                    }

                    // Live static path (fixed points except the anchor)
                    if !viewModel.nonCommitedTraceStatic.isEmpty {
                        let path = viewModel.nonCommitedTraceStatic
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.primaryPath60,
                                lineWidth: 12
                            )
                    }

                    // Live tail (anchor -> interpolated head)
                    if viewModel.nonCommitedTraceTail.count >= 2 {
                        let path = viewModel.nonCommitedTraceTail
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.primaryPath60,
                                lineWidth: 12
                            )
                    }
                } else {
                    if !viewModel.previousTripPath.isEmpty {
                        let path = viewModel.previousTripPath
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.1),
                                lineWidth: 12
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.2),
                                lineWidth: 11
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.3),
                                lineWidth: 10
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.4),
                                lineWidth: 9
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.5),
                                lineWidth: 8
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.6),
                                lineWidth: 7
                            )
                        MapPolyline(coordinates: path)
                            .stroke(
                                AppTheme.Colors.pathHalo.opacity(0.7),
                                lineWidth: 6
                            )
                        MapPolyline(coordinates: path)
                            .stroke(AppTheme.Colors.primaryPath, lineWidth: 5)
                    }
                }

                if !(MainStateDriver.shared.mainState == .review),
                    let coordinate = viewModel.currentLocation?.coordinate
                {
                    Annotation("", coordinate: coordinate, anchor: .center) {
                        Image(systemName: viewModel.locationIconName)
                            .resizable()
                            .font(.title)
                            .rotationEffect(
                                Angle(
                                    degrees: viewModel.displayedArrowRotation
                                ),
                                anchor: .center
                            )
                            .animation(
                                .easeInOut(duration: 0.3),
                                value: viewModel.displayedArrowRotation
                            )
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(AppTheme.Colors.primaryPath)
                    }
                } else {
                    if let start = viewModel.tripMarkers.first {
                        Annotation("Start", coordinate: start, anchor: .bottom)
                        {
                            Image(systemName: "flag.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.green)
                        }
                    }

                    if let end = viewModel.tripMarkers.last {
                        Annotation("End", coordinate: end, anchor: .bottom) {
                            Image(systemName: "flag.checkered")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .simultaneousGesture(
                DragGesture().onChanged { _ in
                    viewModel.userInteracting()
                }
                .simultaneously(
                    with:
                        MagnificationGesture().onChanged { _ in
                            viewModel.userInteracting()
                        }
                )
                .simultaneously(
                    with:
                        RotationGesture().onChanged { _ in
                            viewModel.userInteracting()
                        }
                )
                .simultaneously(
                    with:
                        TapGesture().onEnded {
                            if TripSubMenuViewModel.shared.isVisible
                                && MainStateDriver.shared.mainState == .main
                            {
                                UIImpactFeedbackGenerator(style: .soft)
                                    .impactOccurred()
                                TripStatusViewModel.shared.clearSelected()
                            }

                            if MainStateDriver.shared.mainState != .main {
                                UIImpactFeedbackGenerator(style: .soft)
                                    .impactOccurred()
                                MainStateDriver.shared.mainState = .main
                            }
                        }
                )
            )
            .mapControls {
                MapPitchToggle()
            }
            .mapStyle(.standard)
            .ignoresSafeArea(edges: [.top, .trailing, .bottom])
            .safeAreaInset(edge: .leading) {
                Color.clear.frame(width: 20)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 2)
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                if !(MainStateDriver.shared.mainState == .review) {
                    if CameraManager.shared.orientationMode == .freeRoam {
                        viewModel.updateLastCamera(context.camera)
                        viewModel.saveUserCameraDistance(
                            context.camera.distance
                        )
                    }
                }
            }
            .onMapCameraChange(frequency: .continuous) { context in
                if !(MainStateDriver.shared.mainState == .review) {
                    if CameraManager.shared.orientationMode == .freeRoam {
                        viewModel.updateFreeRoamHeading(context.camera.heading)
                    }
                }
            }

            if viewModel.isLoadingReviewPath {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Loading trip...")
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }
        }
    }

    func recenterOnUser() {
        viewModel.recenter()
    }
}
