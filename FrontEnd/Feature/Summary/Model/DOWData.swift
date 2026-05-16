import Foundation

/// Day-of-week distance summary for a given trip type over an optional date range.
struct DOWData: Equatable {

    // MARK: - Identity / Input
    let tripType: TripType
    let from: Int64?
    let to: Int64?

    // MARK: - Raw Totals (canonical units)
    let meters: [Double]
    let totalMeters: Double
    let maxMeters: Double

    // MARK: - Derived / Display
    let labels: [String]
    let normalizedHeights: [Double]
    let valueTexts: [String]
    let totalText: String

    // MARK: - Init (fetch + derive)
    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType
        self.from = from
        self.to = to

        // Fetch raw meters per DOW; pass through date range if provided.
        let raw = try SegmentStore.shared.fetchDOWMeters(type: tripType, from: from, to: to)

        // Raw totals
        self.meters = raw.meters
        self.totalMeters = raw.meters.reduce(0, +)
        self.maxMeters = raw.meters.max() ?? 0

        // Labels (Sun...Sat) — keep stable order 0...6
        self.labels = (0...6).map { TimeUtility.formatDayOfWeek($0) }

        // Derived / display
        let denom = maxMeters > 0 ? maxMeters : 1.0
        self.normalizedHeights = raw.meters.map { $0 / denom }
        self.valueTexts = raw.meters.map { DistanceUtility.formatter(meters: $0) }
        self.totalText  = DistanceUtility.formatter(meters: totalMeters)
    }
}
