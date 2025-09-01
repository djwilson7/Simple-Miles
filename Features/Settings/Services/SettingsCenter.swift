import Combine
import Foundation
import SwiftUI

// MARK: - Centralized Keys
enum AppSettingKey: String {
    //ACCOUNT --------

    //DISPLAY --------
    case distanceUnit
    case themeOverride
    case materialOverride
    case accentColor
    case primaryHue
    case saturation
    case brightness

    //TRACKING --------
    case minimumTripDistance
    case pauseTimer

}

// MARK: - SettingsCenter
/// Single source of truth for app settings.
/// - Exposes strongly-typed, @Published properties
/// - Loads from and saves to UserDefaults
/// - Observable by any view/service for live updates
@MainActor
final class SettingsCenter: ObservableObject {
    static let shared = SettingsCenter()

    private let ud = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()

    //ACCOUNT

    //DISPLAY
    @Published var distanceUnit: DistanceUnit
    @Published var themeOverride: ThemeOverride
    @Published var materialOverride: MaterialOverride
    @Published private(set) var accentColor: Color = .clear
    @Published var primaryHue: Double
    @Published var saturation: Double
    @Published var brightness: Double

    //TRACKING
    @Published var minimumTripDistance: Double
    @Published var pauseTimer: Double

    private init() {
        //MARK: - READ - ACCOUNT

        //MARK: READ - DISPLAY
        if let storedRawUnit = ud.string(
            forKey: AppSettingKey.distanceUnit.rawValue
        ), let storedUnit = DistanceUnit(rawValue: storedRawUnit) {
            distanceUnit = storedUnit
        } else {
            distanceUnit = .miles
        }

        if let storedRawTheme = ud.string(
            forKey: AppSettingKey.themeOverride.rawValue
        ), let storedTheme = ThemeOverride(rawValue: storedRawTheme) {
            themeOverride = storedTheme
        } else {
            themeOverride = .system
        }

        if let storedRawMaterial = ud.string(
            forKey: AppSettingKey.materialOverride.rawValue
        ), let storedMaterial = MaterialOverride(rawValue: storedRawMaterial) {
            materialOverride = storedMaterial
        } else {
            materialOverride = .clear
        }

        if let storedPrimaryHue = ud.object(
            forKey: AppSettingKey.primaryHue.rawValue
        ) as? Double {
            primaryHue = storedPrimaryHue
        } else {
            primaryHue = 1.0
        }

        if let storedSaturation = ud.object(
            forKey: AppSettingKey.saturation.rawValue
        ) as? Double {
            saturation = storedSaturation
        } else {
            saturation = 1.0
        }

        if let storedBrightness = ud.object(
            forKey: AppSettingKey.brightness.rawValue
        ) as? Double {
            brightness = storedBrightness
        } else {
            brightness = 1.0
        }

        //MARK: READ -TRACKING
        if let minDist = ud.object(
            forKey: AppSettingKey.minimumTripDistance.rawValue
        ) as? Double {
            minimumTripDistance = minDist
        } else {
            minimumTripDistance = 0.2
        }

        if let storedPausedTimer = ud.object(
            forKey: AppSettingKey.pauseTimer.rawValue
        ) as? Double {
            pauseTimer = storedPausedTimer
        } else {
            pauseTimer = 600.0
        }

        //MARK: - WRITE - ACCOUNT

        //MARK: WRITE - DISPLAY
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
                self?.recomputeAccentColor()
            }
            .store(in: &cancellables)

        $saturation
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.saturation.rawValue)
                self?.recomputeAccentColor()
            }
            .store(in: &cancellables)

        $brightness
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.brightness.rawValue)
                self?.recomputeAccentColor()
            }
            .store(in: &cancellables)

        //MARK: WRITE - TRACKING
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

        recomputeAccentColor()
    }

    private func recomputeAccentColor() {
        accentColor = .hsb(h: primaryHue, s: saturation, b: brightness)
    }
}



// MARK: - ENUM - ACCOUNT

// MARK: ENUM - DISPLAY
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
}

enum ThemeOverride: String, CaseIterable, SegmentedPickerOption {
    case system, light, dark
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Follow System"
        case .light: return "Always Light"
        case .dark: return "Always Dark"
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

// MARK: ENUM - TRACKING
