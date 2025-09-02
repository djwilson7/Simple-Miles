import Foundation

/// Aggregated raw counts and distances used for breakdown summaries.
/// - Units:
///   - Distances: meters
///   - Durations: seconds
struct RawBreakdownData {

    // MARK: - Stored Properties (canonical units)
    /// Distance for the specific type in meters.
    let typeMeters: Double
    /// Total distance across all types in meters.
    let totalMeters: Double
    /// Count for the specific type.
    let typeCount: Int
    /// Total count across all types.
    let totalCount: Int
    /// Duration for the specific type in seconds.
    let typeDurationSecs: Double
    /// Total duration across all types in seconds.
    let totalDurationSecs: Double
}
