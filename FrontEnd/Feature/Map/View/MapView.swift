import MapKit
import SwiftUI
import UIKit

/// Renders the main map with live and review paths, user annotation, and camera interactions.
/// Heavy logic (camera/orientation/trace computation) is delegated to MapViewModel.
struct MapView: View {

    // MARK: - Dependencies
    @ObservedObject var viewModel: MapViewModel
    @Environment(\.layout) private var layout

    // MARK: - Body
    var body: some View {
        ZStack {
            map
            loadingOverlay
        }
    }

    // MARK: - Subviews
    private var map: some View {
        Map(
            position: $viewModel.cameraPosition,
            interactionModes: .all
        ) {
            if !(MainStateManager.shared.state == .review) {
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

                if !viewModel.nonCommitedTraceStatic.isEmpty {
                    let path = viewModel.nonCommitedTraceStatic
                    MapPolyline(coordinates: path)
                        .stroke(
                            AppTheme.Colors.primaryPath60,
                            lineWidth: 12
                        )
                }

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

            if !(MainStateManager.shared.state == .review),
               let coordinate = viewModel.currentLocation?.coordinate
            {
                Annotation("", coordinate: coordinate, anchor: .center) {
                    Image(systemName: viewModel.locationIconName)
                        .resizable()
                        .font(.title)
                        .rotationEffect(
                            Angle(degrees: viewModel.displayedArrowRotation),
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
                    Annotation("Start", coordinate: start, anchor: .bottom) {
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
                        if MainStateManager.shared.state != .main {
                            UIImpactFeedbackGenerator(style: .soft)
                                .impactOccurred()
                            MainStateManager.shared.state = .main
                        }
                    }
            )
        )
        .mapControls {
            //left empty to hide base controls from apple
        }
        .mapStyle(.standard)
        
        //Attribution inset for visibility and compliance
        .ignoresSafeArea(edges: [.top, .trailing])
        .safeAreaInset(edge: .leading) {
            Color.clear.frame(width: layout.attributionLeadingInset)
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: layout.attributionBottomInset)
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            if !(MainStateManager.shared.state == .review) {
                if CameraManager.shared.orientationMode == .freeRoam {
                    viewModel.updateLastCamera(context.camera)
                    viewModel.saveUserCameraDistance(context.camera.distance)
                }
            }
        }
        .onMapCameraChange(frequency: .continuous) { context in
            if !(MainStateManager.shared.state == .review) {
                if CameraManager.shared.orientationMode == .freeRoam {
                    viewModel.updateFreeRoamHeading(context.camera.heading)
                }
            }
        }
    }

    private var loadingOverlay: some View {
        Group {
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

    // MARK: - Actions
    func recenterOnUser() {
        viewModel.recenter()
    }
}
