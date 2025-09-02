import Foundation

/// Summary breakdown for a given trip type over an optional date range.
/// Distances are stored in meters; durations in seconds; counts as integers.
/// NOTE: Fields named "*Miles" actually hold raw meters (kept for backward compatibility with existing UI).
struct BreakdownData: Equatable {

    // MARK: - Identity / Input
    let tripType: TripType

    // MARK: - Raw Totals (canonical units)
    let typeDistance: Double
    let totalDistance: Double
    let typeTripCount: Int
    let totalTripCount: Int
    let typeDurationSecs: Double
    let totalDurationSecs: Double

    // MARK: - Derived Shares (0...1) and Display Strings
    let milesPercent: Double
    let milesPercentLabel: String
    let milesLabel: String
    let milesDescription: String

    let durationPercent: Double
    let durationPercentLabel: String
    let durationLabel: String
    let durationDescription: String

    let tripCountPercent: Double
    let tripCountPercentLabel: String
    let tripCountLabel: String
    let tripCountDescription: String

    // MARK: - Init (fetch + derive)
    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType

        let raw = try SegmentStore.shared.fetchBreakdownData(type: tripType, from: from, to: to)

        // Raw totals (meters/seconds/counts)
        self.typeDistance         = raw.typeMeters
        self.totalDistance        = raw.totalMeters
        self.typeTripCount     = raw.typeCount
        self.totalTripCount    = raw.totalCount
        self.typeDurationSecs  = raw.typeDurationSecs
        self.totalDurationSecs = raw.totalDurationSecs

        // Distance share
        let milesShare = (totalDistance > 0) ? (typeDistance / totalDistance) : 0
        self.milesPercent       = milesShare
        self.milesPercentLabel  = PercentageUtility.formatPercent(milesShare)
        self.milesLabel         = "Distance"
        let typeDistText        = DistanceUtility.formatter(meters: typeDistance)
        let totalDistText       = DistanceUtility.formatter(meters: totalDistance)
        self.milesDescription   = "\(typeDistText) / \(totalDistText)"

        // Duration share
        let timeShare = (totalDurationSecs > 0) ? (typeDurationSecs / totalDurationSecs) : 0
        self.durationPercent       = timeShare
        self.durationPercentLabel  = PercentageUtility.formatPercent(timeShare)
        self.durationLabel         = "Duration"
        let typeDurText            = TimeUtility.formatter(typeDurationSecs)
        let totalDurText           = TimeUtility.formatter(totalDurationSecs)
        self.durationDescription   = "\(typeDurText) / \(totalDurText)"

        // Trip count share
        let tripsShare = (totalTripCount > 0) ? Double(typeTripCount) / Double(totalTripCount) : 0
        self.tripCountPercent       = tripsShare
        self.tripCountPercentLabel  = PercentageUtility.formatPercent(tripsShare)
        self.tripCountLabel         = "Trip Count"
        self.tripCountDescription   = "\(typeTripCount) / \(totalTripCount) trips"

        #if DEBUG
        Log("BreakdownData -> Distance: \(milesPercentLabel), Duration: \(durationPercentLabel), Trips: \(tripCountPercentLabel)")
        #endif
    }
}
