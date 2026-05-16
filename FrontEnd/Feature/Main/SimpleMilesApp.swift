import SwiftUI

@main
struct SimpleMilesApp: App {
    @StateObject private var settings = SettingsManager.shared
    @ObservedObject private var locationManager = LocationManager.shared

    private let mapViewModel: MapViewModel
    private let mainViewModel: MainViewModel
    
    init() {
        mapViewModel = MapViewModel()
        mainViewModel = MainViewModel()
    }

    var body: some Scene {
        WindowGroup {
            GeometryReader { geo in
                Group {
                    if locationManager.authorizationStatus == .notDetermined {
                        OnboardingView()
                    } else {
                        MainView(
                            mainViewModel: mainViewModel,
                            mapViewModel: mapViewModel
                        )
                    }
                }
                .environmentObject(settings)
                .preferredColorScheme(settings.themeOverride.colorScheme)
                .layoutGuide(size: geo.size, safeArea: geo.safeAreaInsets)
                .environmentObject(DrivingStateManager.shared)
                .environmentObject(TravelStateManager.shared)
            }
        }
    }
}
