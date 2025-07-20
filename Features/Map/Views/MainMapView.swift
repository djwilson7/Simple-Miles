import SwiftUI
import MapKit

struct MainMapView: View {
    @ObservedObject var viewModel: MapViewModel

    var body: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all) {
            if let coordinate = viewModel.currentLocation?.coordinate {
                Annotation("", coordinate: coordinate, anchor: .center) {
                    Image(systemName: viewModel.locationIconName)
                        .resizable()
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(
                            viewModel.orientationMode == .northUp ? viewModel.currentHeading : 0
                        ))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentHeading)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(.primary)
                }
            }

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
                .onEnded {
                    viewModel.autoFollowEnabled = false
                    viewModel.orientationMode = .free
                }
                .exclusively(before:
                    DragGesture()
                        .onChanged { _ in
                            viewModel.autoFollowEnabled = false
                            viewModel.orientationMode = .free
                        }
                )
                .exclusively(before:
                    LongPressGesture(minimumDuration: 0.05)
                        .onEnded { _ in
                            viewModel.autoFollowEnabled = false
                            viewModel.orientationMode = .free
                        }
                )
        )
    }

    func recenterOnUser() {
        viewModel.recenter()
    }
}
