import Foundation

struct BreakdownData {
    let tripType: TripType

    let typeMiles: Double
    let totalMiles: Double
    let typeTripCount: Int
    let totalTripCount: Int
    let typeDurationSecs: Double
    let totalDurationSecs: Double

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

    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType

        let raw = try SegmentStore.shared.fetchBreakdownData(type: tripType, from: from, to: to)

        self.typeMiles        = raw.typeMeters
        self.totalMiles       = raw.totalMeters
        self.typeTripCount    = raw.typeCount
        self.totalTripCount   = raw.totalCount
        self.typeDurationSecs = raw.typeDurationSecs
        self.totalDurationSecs = raw.totalDurationSecs

        let milesShare = (totalMiles > 0) ? (typeMiles / totalMiles) : 0
        self.milesPercent      = milesShare
        self.milesPercentLabel = PercentageUtility.formatPercent(milesShare)
        self.milesLabel        = "Distance"
        let typeDistText  = DistanceUtility.formatter(meters: typeMiles)
        let totalDistText = DistanceUtility.formatter(meters: totalMiles)
        self.milesDescription  = "\(typeDistText) / \(totalDistText)"

        let timeShare = (totalDurationSecs > 0) ? (typeDurationSecs / totalDurationSecs) : 0
        self.durationPercent      = timeShare
        self.durationPercentLabel = PercentageUtility.formatPercent(timeShare)
        self.durationLabel        = "Duration"
        let typeDurText  = TimeUtility.formatter(typeDurationSecs)
        let totalDurText = TimeUtility.formatter(totalDurationSecs)
        self.durationDescription  = "\(typeDurText) / \(totalDurText)"

        let tripsShare = (totalTripCount > 0) ? Double(typeTripCount) / Double(totalTripCount) : 0
        self.tripCountPercent      = tripsShare
        self.tripCountPercentLabel = PercentageUtility.formatPercent(tripsShare)
        self.tripCountLabel        = "Trip Count"
        self.tripCountDescription  = "\(typeTripCount) / \(totalTripCount) trips"

        Log("MilesData -> Distance: \(milesPercentLabel), Duration: \(durationPercentLabel), Trips: \(tripCountPercentLabel)")
    }
}
