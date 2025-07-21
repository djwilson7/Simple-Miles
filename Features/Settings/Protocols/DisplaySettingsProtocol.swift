import Foundation

protocol DisplaySettingsProtocol: ObservableObject {
    var distanceUnit: DistanceUnit { get set }
    var timeFormat: TimeFormat { get set }
    var systemColorTheme: SystemColorTheme { get set }
    var accessibilityColorTheme: AccessibilityColorTheme { get set }
    var appColorTheme: AppColorTheme { get set }
}

