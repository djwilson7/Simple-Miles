import Foundation

/// Aggregated weekly insights summarizing totals, averages, and extremes.
/// - Units:
///   - Distances: meters
///   - Durations: seconds
struct RawWeekInsights {

    // MARK: - Stored Properties (canonical units)
    let totalMeters: Double
    let totalDurationSecs: Double
    let tripCount: Int

    let avgTripMeters: Double
    let avgTripDurationSecs: Double

    let longestTripMeters: Double
    let longestTripDurationSecs: Double

    /// Busiest day of week by count (0 = Sun … 6 = Sat). -1 indicates none/unknown.
    let busiestDowByCount: Int

    // MARK: - Fixtures / Defaults
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
