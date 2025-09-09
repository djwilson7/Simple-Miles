import Foundation

/// Week-over-week insights for a given trip type.
/// Splits data into "prior" (before current week start) and "current" (from week start to now).
/// Distances are in meters; durations in seconds; formatted strings are precomputed for UI.
struct WeekInsightsData: Equatable {

    // MARK: - Identity / Range
    let tripType: TripType

    /// Start of the current week (Sunday 00:00 local), in milliseconds since epoch.
    let weekStartMs: Int64
    /// "Now" timestamp captured at initialization, in milliseconds since epoch.
    let nowMs: Int64

    // MARK: - Prior Week (formatted display)
    var priorAvgMeters: String?
    var priorAvgDuration: String?
    var priorBusiestDOW: String?
    var priorLongestTrip: String?
    var priorLongestDuration: String?

    // MARK: - Current Week (formatted display)
    var currentAvgMeters: String?
    var currentAvgDuration: String?
    var currentBusiestDOW: String?
    var currentLongestTrip: String?
    var currentLongestDuration: String?

    // MARK: - Raw Differences (current - prior)
    var diffDistance: Double?
    var diffDuration: Double?
    var diffLongestTrip: Double?
    var diffLongestDur: Double?

    // MARK: - Difference Display (formatted)
    var avgMetersChange: String?
    var avgDurationChange: String?
    var longestTripChange: String?
    var longestDurationChange: String?

    // MARK: - Init (fetch + derive)
    init(tripType: TripType, now: Date = Date()) throws {
        self.tripType = tripType

        // Compute start of current week (Sunday 00:00) in local calendar.
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let weekday = cal.component(.weekday, from: startOfToday) // 1=Sun ... 7=Sat
        let daysSinceSunday = (weekday + 6) % 7
        guard let weekStartDate = cal.date(byAdding: .day, value: -daysSinceSunday, to: startOfToday) else {
            throw NSError(domain: "WeekInsights", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compute week start"])
        }

        let weekStartMs = Int64(weekStartDate.timeIntervalSince1970 * 1000)
        let nowMs = Int64(now.timeIntervalSince1970 * 1000)
        self.weekStartMs = weekStartMs
        self.nowMs = nowMs

        // Fetch aggregates: prior (..weekStart) and current (weekStart..)
        let priorRaw = try SegmentStore.shared.fetchWeeklyInsights(type: tripType, to: weekStartMs)
        let currentRaw = try SegmentStore.shared.fetchWeeklyInsights(type: tripType, from: weekStartMs)

        // Prior (formatted)
        self.priorAvgMeters       = DistanceUtility.formatter(meters: priorRaw.avgTripMeters)
        self.priorAvgDuration     = TimeUtility.formatter(priorRaw.avgTripDurationSecs)
        self.priorBusiestDOW      = TimeUtility.formatter(priorRaw.busiestDowByCount)
        self.priorLongestTrip     = DistanceUtility.formatter(meters: priorRaw.longestTripMeters)
        self.priorLongestDuration = TimeUtility.formatter(priorRaw.longestTripDurationSecs)

        // Current (formatted)
        self.currentAvgMeters       = DistanceUtility.formatter(meters: currentRaw.avgTripMeters)
        self.currentAvgDuration     = TimeUtility.formatter(currentRaw.avgTripDurationSecs)
        self.currentBusiestDOW      = TimeUtility.formatter(currentRaw.busiestDowByCount)
        self.currentLongestTrip     = DistanceUtility.formatter(meters: currentRaw.longestTripMeters)
        self.currentLongestDuration = TimeUtility.formatter(currentRaw.longestTripDurationSecs)

        // Raw differences
        self.diffDistance   = currentRaw.avgTripMeters - priorRaw.avgTripMeters
        self.diffDuration   = currentRaw.avgTripDurationSecs - priorRaw.avgTripDurationSecs
        self.diffLongestTrip = currentRaw.longestTripMeters - priorRaw.longestTripMeters
        self.diffLongestDur  = currentRaw.longestTripDurationSecs - priorRaw.longestTripDurationSecs

        // Display differences
        if let d = diffDistance { self.avgMetersChange = DistanceUtility.formatter(meters: d) }
        if let d = diffDuration { self.avgDurationChange = TimeUtility.formatter(d) }
        if let d = diffLongestTrip { self.longestTripChange = DistanceUtility.formatter(meters: d) }
        if let d = diffLongestDur { self.longestDurationChange = TimeUtility.formatter(d) }

        #if DEBUG
        Log("WeekInsights init -> weekStart=\(weekStartMs), type=\(tripType), fetched prior+current")
        #endif
    }
}
