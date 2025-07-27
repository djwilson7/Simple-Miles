import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    var body: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all) {
            MapPolyline(coordinates: viewModel.tracePath)
                .stroke(.green, lineWidth: 7)

                if let coordinate = viewModel.currentLocation?.coordinate {
                    Annotation("", coordinate: coordinate, anchor: .center) {
                        Image(systemName: viewModel.locationIconName)
                            .resizable()
                            .frame(width: 28, height: 28)
                            .rotationEffect(Angle(degrees: viewModel.displayedArrowRotation), anchor: .center)
                            .animation(.easeInOut(duration: 0.3), value: viewModel.displayedArrowRotation)
                            .symbolRenderingMode(.monochrome)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .gesture(DragGesture().onChanged { _ in
                viewModel.isUserInteracting = true
                viewModel.autoFollowEnabled = false
            })
            .gesture(MagnificationGesture().onChanged { _ in
                viewModel.isUserInteracting = true
                viewModel.autoFollowEnabled = false
            })
            .gesture(RotationGesture().onChanged { _ in
                viewModel.isUserInteracting = true
                viewModel.autoFollowEnabled = false
            })
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: []))
            .edgesIgnoringSafeArea(.all)
            .onMapCameraChange(frequency: .continuous) { context in
                viewModel.cameraManager.updateZoomLevel(context.camera.distance)
            }
    }

    func recenterOnUser() {
        viewModel.recenter()
    }
}
