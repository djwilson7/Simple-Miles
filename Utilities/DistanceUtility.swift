import Foundation

enum DistanceUtility {
    static func format(meters: Double, unit: DistanceUnit) -> String {
        let prefix = meters < 0 ? "-" : ""
        let converted: Double
        let suffix: String
        
        switch unit {
        case .miles:
            converted = abs(meters) / 1609.34 //get the positive conversion of meters //to miles here
            suffix = "mi"
        case .kilometers:
            converted = abs(meters) / 1000
            suffix = "km"
        }
        let fmt = converted == 0 ? "%.f" : "%.1f"
        return "\(prefix)\(String(format: fmt , converted))\(suffix)"
    }
}

extension DistanceUtility {
    static func formatter(meters: Double) -> String {
        let raw = UserDefaults.standard.string(forKey: AppSettingKey.distanceUnit.rawValue) ?? DistanceUnit.miles.rawValue
        let unit = DistanceUnit(rawValue: raw) ?? .miles
        return format(meters: meters, unit: unit)
    }
}
