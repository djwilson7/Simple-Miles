import SwiftUI

@main
struct SimpleMilesApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    private let mapViewModel: MapViewModel
    private let mainViewModel: MainViewModel

    init() {
        mapViewModel = MapViewModel()
        mainViewModel = MainViewModel()
    }

    var body: some Scene {
        WindowGroup {
            GeometryReader { geo in
                MainView(
                    mainviewModel: mainViewModel,
                    mapViewModel: mapViewModel
                )
                .layoutGuide(size: geo.size)
                .environmentObject(DrivingStateManager.shared)
                .environmentObject(TravelStateManager.shared)
            }
        }
    }
}
