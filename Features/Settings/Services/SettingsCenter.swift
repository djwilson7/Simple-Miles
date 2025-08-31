import Foundation
import Combine

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

    // MARK: Published settings (start small; add more as needed)
    @Published var distanceUnit: DistanceUnit
    @Published var minimumTripDistance: Double
    @Published var pauseTimer: Double
    
    private init() {
        //ACCOUNT --------
        
        //DISPLAY --------
        if let storedRaw = ud.string(forKey: AppSettingKey.distanceUnit.rawValue), let storedUnit = DistanceUnit(rawValue: storedRaw) {
            distanceUnit = storedUnit
        } else {
            distanceUnit = .miles
        }
        
        //TRACKING --------
        if let minDist = ud.object(forKey: AppSettingKey.minimumTripDistance.rawValue) as? Double {
            minimumTripDistance = minDist
        } else {
            minimumTripDistance = 0.2
        }
        
        if let storedPausedTimer = ud.object(forKey: AppSettingKey.pauseTimer.rawValue) as? Double {
            pauseTimer = storedPausedTimer
        } else {
            pauseTimer = 600.0
        }

        
        //ACCOUNT --------
        
        //DISPLAY --------
        $distanceUnit
            .dropFirst()
            .sink { [weak self] unit in
                self?.ud.set(unit.rawValue, forKey: AppSettingKey.distanceUnit.rawValue)
            }
            .store(in: &cancellables)
        
        
        //TRACKING --------
        $minimumTripDistance
            .dropFirst()
            .sink { [weak self] value in
                self?.ud.set(value, forKey: AppSettingKey.minimumTripDistance.rawValue)
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

// MARK: - Centralized keys for UserDefaults
enum AppSettingKey: String {
    
    //ACCOUNT --------
    
    //DISPLAY --------
    case distanceUnit
    
    //TRACKING --------
    case minimumTripDistance
    case pauseTimer
    

}
//MARK: ENUMS

// ACCOUNT


// DISPLAY
enum DistanceUnit: String, CaseIterable, Identifiable {
    case miles
    case kilometers
    var id: String { rawValue }
    
    var value: String {
        switch self {
        case .miles:
            return "miles"
        case .kilometers :
            return "kilometers"
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

// TRACKING


