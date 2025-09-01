import Foundation

struct PercentageUtility {
    static func formatPercent(_ ratio: Double) -> String {
        let pct = ratio * 100
        let rounded1 = (pct * 10).rounded() / 10
        let isWhole = abs(rounded1 - rounded1.rounded()) < 1e-9
        return isWhole ? String(format: "%.0f%%", rounded1)
                       : String(format: "%.1f%%", rounded1)
    }
}
