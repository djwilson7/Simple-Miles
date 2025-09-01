import SwiftUI

@main
struct SimpleMilesApp: App {
    @StateObject private var settings = SettingsCenter.shared

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
                    mainViewModel: mainViewModel,
                    mapViewModel: mapViewModel
                )
                .environmentObject(settings)
                .preferredColorScheme(settings.themeOverride.colorScheme)
                .layoutGuide(size: geo.size)
                .environmentObject(DrivingStateManager.shared)
                .environmentObject(TravelStateManager.shared)
            }
        }
    }
}
