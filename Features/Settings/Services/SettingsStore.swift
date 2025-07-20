import Foundation
import CoreLocation

final class SettingsStore: SettingsStoreProtocol {
    static let shared = SettingsStore()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Recording
    var motionSensitivity: MotionSensitivityLevel {
        get { getEnum(.motionSensitivity, default: .medium) }
        set { set(.motionSensitivity, value: newValue.rawValue) }
    }

    var pauseDuration: TimeInterval {
        get { defaults.double(forKey: .pauseDuration).nonZeroOr(600) }
        set { set(.pauseDuration, value: newValue) }
    }

    var minimumTripDistance: Double {
        get { defaults.double(forKey: .minimumTripDistance).nonZeroOr(0.25) }
        set { set(.minimumTripDistance, value: newValue) }
    }

    var baseSpeedThreshold: CLLocationSpeed {
        get { defaults.double(forKey: .baseSpeedThreshold).nonZeroOr(2.5) }
        set { set(.baseSpeedThreshold, value: newValue) }
    }

    var baseDistanceThreshold: CLLocationDistance {
        get { defaults.double(forKey: .baseDistanceThreshold).nonZeroOr(50.0) }
        set { set(.baseDistanceThreshold, value: newValue) }
    }

    // MARK: - Display
    var distanceUnit: DistanceUnit {
        get { getEnum(.distanceUnit, default: .miles) }
        set { set(.distanceUnit, value: newValue.rawValue) }
    }

    var timeFormat: TimeFormat {
        get { getEnum(.timeFormat, default: .twelveHour) }
        set { set(.timeFormat, value: newValue.rawValue) }
    }

    var primaryColorTheme: ColorTheme {
        get { getEnum(.primaryColorTheme, default: .system) }
        set { set(.primaryColorTheme, value: newValue.rawValue) }
    }

    var secondaryColorTheme: ColorTheme {
        get { getEnum(.secondaryColorTheme, default: .system) }
        set { set(.secondaryColorTheme, value: newValue.rawValue) }
    }

    // MARK: - Export
    var includeRawCoordinates: Bool {
        get { defaults.bool(forKey: .includeRawCoordinates) }
        set { set(.includeRawCoordinates, value: newValue) }
    }

    var exportFieldOptions: Set<ExportField> {
        get {
            guard let data = defaults.data(forKey: .exportFieldOptions),
                  let decoded = try? JSONDecoder().decode(Set<ExportField>.self, from: data) else {
                return Set(ExportField.allCases)
            }
            return decoded
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                defaults.set(encoded, forKey: SettingsKey.exportFieldOptions.rawValue)
            }
        }
    }

    var defaultExportFileNamePrefix: String {
        get { defaults.string(forKey: .defaultExportFileNamePrefix) ?? "Trip" }
        set { set(.defaultExportFileNamePrefix, value: newValue) }
    }

    // MARK: - Classification
    var defaultTripType: TripType {
        get { getEnum(.defaultTripType, default: .personal) }
        set { set(.defaultTripType, value: newValue.rawValue) }
    }

    var businessModeEnabled: Bool {
        get { defaults.bool(forKey: .businessModeEnabled) }
        set { set(.businessModeEnabled, value: newValue) }
    }

    var useProbabilisticTagging: Bool {
        get { defaults.bool(forKey: .useProbabilisticTagging) }
        set { set(.useProbabilisticTagging, value: newValue) }
    }

    var classificationMode: ClassificationMode {
        get { getEnum(.classificationMode, default: .accumulate) }
        set { set(.classificationMode, value: newValue.rawValue) }
    }

    var customLabels: [String] {
        get { defaults.stringArray(forKey: .customLabels) ?? [] }
        set { defaults.set(newValue, forKey: SettingsKey.customLabels.rawValue) }
    }

    // MARK: - Internal Helpers
    private func getEnum<T: RawRepresentable>(_ key: SettingsKey, default defaultValue: T) -> T where T.RawValue == String {
        guard let raw = defaults.string(forKey: key.rawValue),
              let value = T(rawValue: raw) else {
            return defaultValue
        }
        return value
    }

    private func set<T>(_ key: SettingsKey, value: T) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    var privacyConsentLevel: PrivacyConsentLevel {
        get { getEnum(.privacyConsentLevel, default: .none) }
        set { set(.privacyConsentLevel, value: newValue.rawValue) }
    }
}

private extension UserDefaults {
    func double(forKey key: SettingsKey) -> Double {
        self.double(forKey: key.rawValue)
    }

    func bool(forKey key: SettingsKey) -> Bool {
        self.bool(forKey: key.rawValue)
    }

    func string(forKey key: SettingsKey) -> String? {
        self.string(forKey: key.rawValue)
    }

    func stringArray(forKey key: SettingsKey) -> [String]? {
        self.stringArray(forKey: key.rawValue)
    }

    func data(forKey key: SettingsKey) -> Data? {
        self.data(forKey: key.rawValue)
    }
    


}

private extension Double {
    func nonZeroOr(_ fallback: Double) -> Double {
        self == 0 ? fallback : self
    }
}
