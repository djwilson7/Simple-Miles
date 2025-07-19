import SwiftUI
import MapKit

struct MainMapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all) {
            UserAnnotation()

            if viewModel.pathPoints.count > 1 {
                let coords = viewModel.pathPoints.map { $0.locationCoordinate }
                MapPolyline(coordinates: coords)
                    .stroke(Color.green, lineWidth: 5)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: []))
        .edgesIgnoringSafeArea(.all)
        .simultaneousGesture(
            TapGesture()
                .onEnded { viewModel.autoFollowEnabled = false }
                .exclusively(before:
                    DragGesture()
                        .onChanged { _ in viewModel.autoFollowEnabled = false }
                )
                .exclusively(before:
                    LongPressGesture(minimumDuration: 0.05)
                        .onEnded { _ in viewModel.autoFollowEnabled = false }
                )
        )
        .onAppear {
            viewModel.requestLocationPermission()
            viewModel.startTracking()
        }
    }

    func recenterOnUser() {
        viewModel.recenter()
    }
}
