import Foundation

struct DistanceUtility {
    static func formatter(meters: Double) -> String {
        let prefix = meters < 0 ? "-" : ""
        
        let convertedMeters = abs(meters) / 1609.34 //get the positive conversion of meters //to miles here
        let fmt = convertedMeters == 0 ? "%.f" : "%.1f"
        
        return "\(prefix)\(String(format: fmt , convertedMeters))mi"
    }
}
