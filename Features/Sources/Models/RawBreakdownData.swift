import Foundation

/// Raw, storage-only payload (no formatting).
struct RawBreakdownData {
    let typeMeters: Double
    let totalMeters: Double
    let typeCount: Int
    let totalCount: Int
    let typeDurationSecs: Double
    let totalDurationSecs: Double
}
