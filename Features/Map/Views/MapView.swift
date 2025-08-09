import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    
    var body: some View {
        ZStack {
            Map(position: $viewModel.cameraPosition, interactionModes: .all) {
                if !viewModel.tripViewModel.isReviewing {
                    // Committed (stored) path
                    if !viewModel.commitedTracePath.isEmpty {
                        MapPolyline(coordinates: viewModel.commitedTracePath)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 7
                            )
                    }
                    
                    // Live static path (fixed points except the anchor)
                    if !viewModel.nonCommitedTraceStatic.isEmpty {
                        MapPolyline(coordinates: viewModel.nonCommitedTraceStatic)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.6), Color.red.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 7
                            )
                    }
                    
                    // Live tail (anchor -> interpolated head)
                    if viewModel.nonCommitedTraceTail.count >= 2 {
                        MapPolyline(coordinates: viewModel.nonCommitedTraceTail)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.orange.opacity(0.6), Color.red.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 7
                            )
                    }
                } else {
                    if !viewModel.previousTripPath.isEmpty {
                        MapPolyline(coordinates: viewModel.previousTripPath)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.purple.opacity(0.6), Color.black.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 7
                            )
                    }
                }

                if !viewModel.tripViewModel.isReviewing,
                   let coordinate = viewModel.currentLocation?.coordinate {
                    Annotation("", coordinate: coordinate, anchor: .center) {
                        Image(systemName: viewModel.locationIconName)
                            .resizable()
                            .frame(width: 28, height: 28)
                            .rotationEffect(Angle(degrees: viewModel.displayedArrowRotation), anchor: .center)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.displayedArrowRotation)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.primary)
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
                .simultaneously(with:
                    MagnificationGesture().onChanged { _ in
                        viewModel.userInteracting()
                    }
                )
                .simultaneously(with:
                    RotationGesture().onChanged { _ in
                        viewModel.userInteracting()
                    }
                )
                .simultaneously(with:
                    TapGesture().onEnded {
                        viewModel.userInteracting()
                    }
                )
            )
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: []))
            .edgesIgnoringSafeArea(.all)
            .onMapCameraChange(frequency: .onEnd) { context in
                if !viewModel.tripViewModel.isReviewing {
                    if CameraManager.shared.orientationMode == .freeRoam {
                        viewModel.updateLastCamera(context.camera)
                        viewModel.saveUserCameraDistance(context.camera.distance)
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
