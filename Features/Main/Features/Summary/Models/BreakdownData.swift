import Foundation

struct BreakdownData {
    // MARK: Scope
    let tripType: TripType

    // MARK: Raw (distance, count, duration)
    let typeMiles: Double          // meters for this trip type
    let totalMiles: Double
    let typeTripCount: Int
    let totalTripCount: Int
    let typeDurationSecs: Double
    let totalDurationSecs: Double

    // MARK: UI-ready: Distance
    let milesPercent: Double          // 0...1
    let milesPercentLabel: String     // "54.1%" or "54%"
    let milesLabel: String            // "Distance"
    let milesDescription: String      // "150 mi / 300 mi"

    // MARK: UI-ready: Duration
    let durationPercent: Double
    let durationPercentLabel: String
    let durationLabel: String         // "Duration"
    let durationDescription: String   // "1h 12m / 4h 15m"

    // MARK: UI-ready: Trip Count
    let tripCountPercent: Double
    let tripCountPercentLabel: String
    let tripCountLabel: String        // "Trip Count"
    let tripCountDescription: String  // "12 / 38 trips"

    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType

        let raw = try TripSegmentStore.shared.fetchBreakdownData(type: tripType, from: from, to: to)

        self.typeMiles        = raw.typeMeters
        self.totalMiles       = raw.totalMeters
        self.typeTripCount    = raw.typeCount
        self.totalTripCount   = raw.totalCount
        self.typeDurationSecs = raw.typeDurationSecs
        self.totalDurationSecs = raw.totalDurationSecs

        // ---- Distance ----
        let milesShare = (totalMiles > 0) ? (typeMiles / totalMiles) : 0
        self.milesPercent      = milesShare
        self.milesPercentLabel = PercentageUtility.formatPercent(milesShare)
        self.milesLabel        = "Distance"
        let typeDistText  = DistanceUtility.formatter(meters: typeMiles)
        let totalDistText = DistanceUtility.formatter(meters: totalMiles)
        self.milesDescription  = "\(typeDistText) / \(totalDistText)"

        // ---- Duration ----
        let timeShare = (totalDurationSecs > 0) ? (typeDurationSecs / totalDurationSecs) : 0
        self.durationPercent      = timeShare
        self.durationPercentLabel = PercentageUtility.formatPercent(timeShare)
        self.durationLabel        = "Duration"
        let typeDurText  = TimeUtility.formatter(typeDurationSecs)
        let totalDurText = TimeUtility.formatter(totalDurationSecs)
        self.durationDescription  = "\(typeDurText) / \(totalDurText)"

        // ---- Trip Count ----
        let tripsShare = (totalTripCount > 0) ? Double(typeTripCount) / Double(totalTripCount) : 0
        self.tripCountPercent      = tripsShare
        self.tripCountPercentLabel = PercentageUtility.formatPercent(tripsShare)
        self.tripCountLabel        = "Trip Count"
        self.tripCountDescription  = "\(typeTripCount) / \(totalTripCount) trips"

        Log("MilesData -> Distance: \(milesPercentLabel), Duration: \(durationPercentLabel), Trips: \(tripCountPercentLabel)")
    }
}
