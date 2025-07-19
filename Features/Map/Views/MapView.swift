import SwiftUI
import MapKit

struct MainMapView: View {
    @StateObject private var viewModel = MapViewModel()
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )

    var body: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.requestLocationPermission()
            viewModel.startTracking()
        }
        .onReceive(viewModel.$currentLocation.compactMap { $0 }) { newLocation in
            position = .region(
                MKCoordinateRegion(
                    center: newLocation.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            )
        }
    }
}

#Preview {
    MainMapView()
}
