import Combine
import Foundation
import SwiftUI

enum AppSettingKey: String {
    case distanceUnit
    case themeOverride
    case materialOverride

    case primaryHue
    case saturation
    case brightness

    case minimumTripDistance
    case pauseTimer

}

private struct Defaults {

    static let distanceUnit: DistanceUnit = .miles
    static let themeOverride: ThemeOverride = .system
    static let materialOverride: MaterialOverride = .clear
    static let primaryHue: Double = 1.0
    static let saturation: Double = 0.1
    static let brightness: Double = 0.1

    static let minimumTripDistance: Double = 0.2
    static let pauseTimer: Double = 600.0
}

@MainActor
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private let ud = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()


    @Published var distanceUnit: DistanceUnit
    @Published var themeOverride: ThemeOverride
    @Published var materialOverride: MaterialOverride
    var accentColor: Color { .hsb(h: primaryHue, s: saturation, b: brightness) }
    var minDistanceMeters: Double { minimumTripDistance * distanceUnit.factor }
    @Published var primaryHue: Double
    @Published var saturation: Double
    @Published var brightness: Double

    @Published var minimumTripDistance: Double
    @Published var pauseTimer: Double

    private init() {

        if let storedRawUnit = ud.string(
            forKey: AppSettingKey.distanceUnit.rawValue
        ), let storedUnit = DistanceUnit(rawValue: storedRawUnit) {
            distanceUnit = storedUnit
        } else {
            distanceUnit = Defaults.distanceUnit
        }

        if let storedRawTheme = ud.string(
            forKey: AppSettingKey.themeOverride.rawValue
        ), let storedTheme = ThemeOverride(rawValue: storedRawTheme) {
            themeOverride = storedTheme
        } else {
            themeOverride = Defaults.themeOverride
        }

        if let storedRawMaterial = ud.string(
            forKey: AppSettingKey.materialOverride.rawValue
        ), let storedMaterial = MaterialOverride(rawValue: storedRawMaterial) {
            materialOverride = storedMaterial
        } else {
            materialOverride = Defaults.materialOverride
        }

        if let storedPrimaryHue = ud.object(
            forKey: AppSettingKey.primaryHue.rawValue
        ) as? Double {
            primaryHue = storedPrimaryHue
        } else {
            primaryHue = Defaults.primaryHue
        }

        if let storedSaturation = ud.object(
            forKey: AppSettingKey.saturation.rawValue
        ) as? Double {
            saturation = storedSaturation
        } else {
            saturation = Defaults.saturation
        }

        if let storedBrightness = ud.object(
            forKey: AppSettingKey.brightness.rawValue
        ) as? Double {
            brightness = storedBrightness
        } else {
            brightness = Defaults.brightness
        }

        if let minDist = ud.object(
            forKey: AppSettingKey.minimumTripDistance.rawValue
        ) as? Double {
            minimumTripDistance = minDist
        } else {
            minimumTripDistance = Defaults.minimumTripDistance
        }

        if let storedPausedTimer = ud.object(
            forKey: AppSettingKey.pauseTimer.rawValue
        ) as? Double {
            pauseTimer = storedPausedTimer
        } else {
            pauseTimer = Defaults.pauseTimer
        }

        $distanceUnit
            .dropFirst()
            .sink { [weak self] unit in
                self?.ud.set(
                    unit.rawValue,
                    forKey: AppSettingKey.distanceUnit.rawValue
                )
            }
            .store(in: &cancellables)

        $themeOverride
            .dropFirst()
            .sink { [weak self] theme in
                self?.ud.set(
                    theme.rawValue,
                    forKey: AppSettingKey.themeOverride.rawValue
                )
            }
            .store(in: &cancellables)

        $materialOverride
            .dropFirst()
            .sink { [weak self] material in
                self?.ud.set(
                    material.rawValue,
                    forKey: AppSettingKey.materialOverride.rawValue
                )
            }
            .store(in: &cancellables)

        $primaryHue
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.primaryHue.rawValue)
            }
            .store(in: &cancellables)

        $saturation
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.saturation.rawValue)
            }
            .store(in: &cancellables)

        $brightness
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.brightness.rawValue)
            }
            .store(in: &cancellables)

        $minimumTripDistance
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(
                    value,
                    forKey: AppSettingKey.minimumTripDistance.rawValue
                )
            }
            .store(in: &cancellables)

        $pauseTimer
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.pauseTimer.rawValue)
            }
            .store(in: &cancellables)
    }
}

enum DistanceUnit: String, CaseIterable, SegmentedPickerOption {
    case miles, kilometers
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .miles: return "Miles (mi)"
        case .kilometers: return "Kilometers (km)"
        }
    }

    var abb: String {
        switch self {
        case .miles:
            return "mi"
        case .kilometers:
            return "km"
        }
    }

    var factor: Double {
        switch self {
        case .miles:
            return 1609.34
        case .kilometers:
            return 1000.00
        }
    }
}

enum ThemeOverride: String, CaseIterable, SegmentedPickerOption {
    case system, light, dark
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum MaterialOverride: String, CaseIterable, SegmentedPickerOption {
    case clear, regular, frosted, none
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .clear: return "Clear"
        case .regular: return "Regular"
        case .frosted: return "Frosted"
        case .none: return "Solid"
        }
    }
}

