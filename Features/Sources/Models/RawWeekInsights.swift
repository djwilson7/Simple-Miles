
import Foundation

/// Raw weekly insight aggregates returned from storage/DAO.
/// All values are unformatted and expressed in base units:
/// - distances: meters
/// - durations: seconds
/// - counts: trips
/// - busiestDowByCount: 0=Sun … 6=Sat, -1 if no data
struct RawWeekInsights {
    // Totals over the requested window
    let totalMeters: Double
    let totalDurationSecs: Double
    let tripCount: Int

    // Averages per trip over the requested window
    let avgTripMeters: Double
    let avgTripDurationSecs: Double

    // Extremes within the window
    let longestTripMeters: Double
    let longestTripDurationSecs: Double

    // Weekday with the highest **trip count** (Sun=0 … Sat=6). -1 if window has no trips
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
