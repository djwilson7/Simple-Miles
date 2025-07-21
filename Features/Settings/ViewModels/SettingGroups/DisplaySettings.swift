import Foundation

final class DisplaySettings: DisplaySettingsProtocol {
    @Published var distanceUnit: DistanceUnit
    @Published var timeFormat: TimeFormat
    @Published var systemColorTheme: SystemColorTheme
    @Published var accessibilityColorTheme: AccessibilityColorTheme
    @Published var appColorTheme: AppColorTheme

    init(store: SettingsStoreProtocol) {
        self.distanceUnit = store.distanceUnit
        self.timeFormat = store.timeFormat
        self.systemColorTheme = store.systemColorTheme
        self.accessibilityColorTheme = store.accessibilityColorTheme
        self.appColorTheme = store.appColorTheme
    }
}
