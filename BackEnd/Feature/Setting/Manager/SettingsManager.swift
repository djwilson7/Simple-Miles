import Foundation
import Combine
import SwiftUI

/// Centralized settings manager:
/// - Owns persisted app preferences (UserDefaults)
/// - Publishes settings for UI and other managers
/// - Provides derived values (e.g., accentColor, minDistanceMeters)
@MainActor
final class SettingsManager: ObservableObject {

    // MARK: - Singleton
    static let shared = SettingsManager()

    // MARK: - Dependencies
    private let userDefaults = UserDefaults.standard

    // MARK: - Published State (Outputs)
    @Published var distanceUnit: DistanceUnit
    @Published var themeOverride: ThemeOverride
    @Published var materialOverride: MaterialOverride

    // Derived (computed) outputs
    var accentColor: Color { .hsb(h: primaryHue, s: saturation, b: brightness) }
    var minDistanceMeters: Double { minimumTripDistance * distanceUnit.factor }

    @Published var primaryHue: Double
    @Published var saturation: Double
    @Published var brightness: Double

    @Published var minimumTripDistance: Double
    @Published var pauseTimer: Double

    // MARK: - Actions
    func eraseAllData() {
        do {
            try Database.shared.exec("DELETE FROM trips;")
            try Database.shared.exec("DELETE FROM trash;")
            try Database.shared.exec("DELETE FROM trip_blobs;")
            SegmentStore.shared.tripTotalsUpdated.send()
        } catch {
            Log("Failed to erase all data: \(error)")
        }
    }

    func exportCSV() -> URL? {
        do {
            let trips = try TripsDAO.fetchAllTrips()
            guard !trips.isEmpty else { return nil }

            let unit = distanceUnit
            let unitLabel = unit.displayName
            
            var csv = "Trip ID,Category,Date,Start Time,End Time,Distance (\(unitLabel)),Duration,Raw Meters,Raw Seconds\n"
            
            let dfDate = DateFormatter()
            dfFormat(dfDate, "yyyy-MM-dd")
            
            let dfTime = DateFormatter()
            dfFormat(dfTime, "HH:mm:ss")

            // Group by category, then sort groups by date
            let groupedTrips = Dictionary(grouping: trips, by: { $0.type })
            let sortedCategoryIds = groupedTrips.keys.sorted()

            for typeId in sortedCategoryIds {
                let categoryTrips = groupedTrips[typeId]?.sorted(by: { $0.startTs < $1.startTs }) ?? []
                let categoryName = TripType(dbValue: typeId)?.name.capitalized ?? "Unknown"
                
                // Optional: Add a separator row for each category if not the first
                if typeId != sortedCategoryIds.first {
                    csv.append("\n")
                }

                for t in categoryTrips {
                    let startDate = Date(timeIntervalSince1970: Double(t.startTs) / 1000)
                    let endDate = Date(timeIntervalSince1970: Double(t.endTs) / 1000)
                    
                    let dateStr = dfDate.string(from: startDate)
                    let startStr = dfTime.string(from: startDate)
                    let endStr = dfTime.string(from: endDate)
                    
                    let distanceFormatted = String(format: "%.2f", t.distanceM / unit.factor)
                    let durationFormatted = TimeUtility.formatter(t.durationS)
                    
                    let row = "\"\(t.id)\",\(categoryName),\(dateStr),\(startStr),\(endStr),\(distanceFormatted),\(durationFormatted),\(t.distanceM),\(t.durationS)\n"
                    csv.append(row)
                }
            }

            let timestamp = dfDate.string(from: Date())
            let fileName = "SimpleMiles_Export_\(timestamp).csv"
            
            // Use Documents directory for more reliable file access/sharing on iOS
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docsURL.appendingPathComponent(fileName)
            
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            Log("Failed to export CSV: \(error)")
            return nil
        }
    }

    private func dfFormat(_ df: DateFormatter, _ format: String) {
        df.dateFormat = format
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
    }

    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    private init() {
        // Load persisted values or fall back to defaults
        if let storedRawUnit = userDefaults.string(forKey: AppSettingKey.distanceUnit.rawValue),
           let storedUnit = DistanceUnit(rawValue: storedRawUnit) {
            distanceUnit = storedUnit
        } else {
            distanceUnit = Defaults.distanceUnit
        }

        if let storedRawTheme = userDefaults.string(forKey: AppSettingKey.themeOverride.rawValue),
           let storedTheme = ThemeOverride(rawValue: storedRawTheme) {
            themeOverride = storedTheme
        } else {
            themeOverride = Defaults.themeOverride
        }

        if let storedRawMaterial = userDefaults.string(forKey: AppSettingKey.materialOverride.rawValue),
           let storedMaterial = MaterialOverride(rawValue: storedRawMaterial) {
            materialOverride = storedMaterial
        } else {
            materialOverride = Defaults.materialOverride
        }

        if let storedPrimaryHue = userDefaults.object(forKey: AppSettingKey.primaryHue.rawValue) as? Double {
            primaryHue = storedPrimaryHue
        } else {
            primaryHue = Defaults.primaryHue
        }

        if let storedSaturation = userDefaults.object(forKey: AppSettingKey.saturation.rawValue) as? Double {
            saturation = storedSaturation
        } else {
            saturation = Defaults.saturation
        }

        if let storedBrightness = userDefaults.object(forKey: AppSettingKey.brightness.rawValue) as? Double {
            brightness = storedBrightness
        } else {
            brightness = Defaults.brightness
        }

        if let minDist = userDefaults.object(forKey: AppSettingKey.minimumTripDistance.rawValue) as? Double {
            minimumTripDistance = minDist
        } else {
            minimumTripDistance = Defaults.minimumTripDistance
        }

        if let storedPausedTimer = userDefaults.object(forKey: AppSettingKey.pauseTimer.rawValue) as? Double {
            pauseTimer = storedPausedTimer
        } else {
            pauseTimer = Defaults.pauseTimer
        }

        bindPersistence()
    }

    // MARK: - Bindings (Persistence wiring)
    private func bindPersistence() {
        $distanceUnit
            .dropFirst()
            .sink { [weak self] unit in
                self?.userDefaults.set(unit.rawValue, forKey: AppSettingKey.distanceUnit.rawValue)
            }
            .store(in: &cancellables)

        $themeOverride
            .dropFirst()
            .sink { [weak self] theme in
                self?.userDefaults.set(theme.rawValue, forKey: AppSettingKey.themeOverride.rawValue)
            }
            .store(in: &cancellables)

        $materialOverride
            .dropFirst()
            .sink { [weak self] material in
                self?.userDefaults.set(material.rawValue, forKey: AppSettingKey.materialOverride.rawValue)
            }
            .store(in: &cancellables)

        $primaryHue
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: AppSettingKey.primaryHue.rawValue)
            }
            .store(in: &cancellables)

        $saturation
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: AppSettingKey.saturation.rawValue)
            }
            .store(in: &cancellables)

        $brightness
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: AppSettingKey.brightness.rawValue)
            }
            .store(in: &cancellables)

        $minimumTripDistance
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: AppSettingKey.minimumTripDistance.rawValue)
            }
            .store(in: &cancellables)

        $pauseTimer
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: AppSettingKey.pauseTimer.rawValue)
            }
            .store(in: &cancellables)
    }
}

// MARK: - Keys
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

// MARK: - Defaults
private struct Defaults {
    static let distanceUnit: DistanceUnit = .miles
    static let themeOverride: ThemeOverride = .system
    static let materialOverride: MaterialOverride = .clear

    static let primaryHue: Double = 1.0
    static let saturation: Double = 0.1
    static let brightness: Double = 0.1

    static let minimumTripDistance: Double = 0.2
    static let pauseTimer: Double = 150.0
}

// MARK: - Setting Types
enum DistanceUnit: String, CaseIterable, SegmentedPickerOption {
    case miles, kilometers
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .miles: return "Miles"
        case .kilometers: return "Kilometers"
        }
    }

    var abb: String {
        switch self {
        case .miles: return "mi"
        case .kilometers: return "km"
        }
    }

    var factor: Double {
        switch self {
        case .miles: return 1609.34
        case .kilometers: return 1000.00
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
