
import Foundation

struct RawWeekInsights {
    let totalMeters: Double
    let totalDurationSecs: Double
    let tripCount: Int

    let avgTripMeters: Double
    let avgTripDurationSecs: Double

    let longestTripMeters: Double
    let longestTripDurationSecs: Double

    let busiestDowByCount: Int

    static let empty = RawWeekInsights(
        totalMeters: 0,
        totalDurationSecs: 0,
        tripCount: 0,
        avgTripMeters: 0,
        avgTripDurationSecs: 0,
        longestTripMeters: 0,
        longestTripDurationSecs: 0,
        busiestDowByCount: -1
    )
}
