import Foundation

/// Raw tuple is assumed to be returned by storage layer:
/// `TripSegmentStore.shared.fetchWeeklyInsights(type:weekStartMs:) -> (thisWeek: RawWeekInsights, baseline: RawWeekInsights)`
struct WeekInsightsData {
    // MARK: Scope
    let tripType: TripType

    // MARK: Window (epoch ms, local-week aligned)
    let weekStartMs: Int64      // most-recent Sunday 00:00 local
    let nowMs: Int64            // capture-time (for reference)
    
    var priorAvgMeters: String?
    var priorAvgDuration: String?
    var priorBusiestDOW: String?
    var priorLongestTrip: String?
    var priorLongestDuration: String?
    
    var currentAvgMeters: String?
    var currentAvgDuration: String?
    var currentBusiestDOW: String?
    var currentLongestTrip: String?
    var currentLongestDuration: String?
    
    var diffDistance : Double?
    var diffDuration: Double?
    var diffLongestTrip: Double?
    var diffLongestDur: Double?
    
    var avgMetersChange: String?
    var avgDurationChange: String?
    var longestTripChange: String?
    var longestDurationChange: String?

    init(tripType: TripType, now: Date = Date()) throws {
        self.tripType = tripType

        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: now)
        let weekday = cal.component(.weekday, from: startOfToday)
        let daysSinceSunday = (weekday + 6) % 7   // Sun→0, Mon→1, … Sat→6
        guard let weekStartDate = cal.date(byAdding: .day, value: -daysSinceSunday, to: startOfToday) else {
            throw NSError(domain: "WeekInsights", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compute week start"])
        }

        let weekStartMs = Int64(weekStartDate.timeIntervalSince1970 * 1000)
        let nowMs = Int64(now.timeIntervalSince1970 * 1000)
        self.weekStartMs = weekStartMs
        self.nowMs = nowMs

        let priorRaw = try TripSegmentStore.shared.fetchWeeklyInsights(type: tripType, to: weekStartMs)
        let currentRaw = try TripSegmentStore.shared.fetchWeeklyInsights(type: tripType, from: weekStartMs)

        self.priorAvgMeters         = DistanceUtility.formatter(meters: priorRaw.avgTripMeters)
        self.priorAvgDuration       = TimeUtility.formatter( priorRaw.avgTripDurationSecs )
        self.priorBusiestDOW        = TimeUtility.formatter( priorRaw.busiestDowByCount )
        self.priorLongestTrip       = DistanceUtility.formatter(meters: priorRaw.longestTripMeters )
        self.priorLongestDuration   = TimeUtility.formatter( priorRaw.longestTripDurationSecs )
        
        self.currentAvgMeters       = DistanceUtility.formatter(meters: currentRaw.avgTripMeters )
        self.currentAvgDuration     = TimeUtility.formatter( currentRaw.avgTripDurationSecs )
        self.currentBusiestDOW      = TimeUtility.formatter( currentRaw.busiestDowByCount )
        self.currentLongestTrip     = DistanceUtility.formatter(meters: currentRaw.longestTripMeters )
        self.currentLongestDuration = TimeUtility.formatter( currentRaw.longestTripDurationSecs )
        
        self.diffDistance = currentRaw.avgTripMeters - priorRaw.avgTripMeters
        self.diffDuration = currentRaw.avgTripDurationSecs - priorRaw.avgTripDurationSecs
        self.diffLongestTrip = currentRaw.longestTripMeters - priorRaw.longestTripMeters
        self.diffLongestDur = currentRaw.longestTripDurationSecs - priorRaw.longestTripDurationSecs
        
        self.avgMetersChange = DistanceUtility.formatter(meters: diffDistance!)
        self.avgDurationChange = TimeUtility.formatter(diffDuration!)
        self.longestTripChange = DistanceUtility.formatter(meters: diffLongestTrip!)
        self.longestDurationChange = TimeUtility.formatter(diffLongestDur!)
        
        Log("WeekInsights init -> weekStart=\(weekStartMs), type=\(tripType), fetched prior+current")
    }
}
