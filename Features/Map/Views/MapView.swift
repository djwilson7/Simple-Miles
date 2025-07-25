import SwiftUI
import MapKit

struct MapView: View {
    @ObservedObject var viewModel: MapViewModel
    var body: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all){
                ForEach(viewModel.traceSegments.indices, id: \.self) { index in
                    MapPolyline(coordinates: viewModel.traceSegments[index])
                        .stroke(.green, lineWidth: 7)
                }

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
