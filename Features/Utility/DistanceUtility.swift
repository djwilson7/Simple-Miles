import Foundation

struct DistanceUtility {
    static func formatter(meters: Double) -> String {
        let miles = meters / 1609.34
        if miles < 0.01 {
            return "0 mi"
        }
        return String(format: "%.1f mi", miles)
    }
}
