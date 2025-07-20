import Foundation

enum ColorTheme: String, CaseIterable {
    case system
    case light
    case dark
    case customBlue
    case customOrange
}

protocol DisplaySettingsProtocol: ObservableObject {
    var distanceUnit: DistanceUnit { get set }
    var timeFormat: TimeFormat { get set }
    var primaryColorTheme: ColorTheme { get set }
    var secondaryColorTheme: ColorTheme { get set }
}
