import Foundation

final class DisplaySettings: DisplaySettingsProtocol {
    @Published var distanceUnit: DistanceUnit
    @Published var timeFormat: TimeFormat
    @Published var primaryColorTheme: ColorTheme
    @Published var secondaryColorTheme: ColorTheme

    init(store: SettingsStoreProtocol) {
        self.distanceUnit = store.distanceUnit
        self.timeFormat = store.timeFormat
        self.primaryColorTheme = store.primaryColorTheme
        self.secondaryColorTheme = store.secondaryColorTheme
    }
}
