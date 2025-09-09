import Foundation

/// Start-hour histogram for a given trip type over an optional date range.
/// Values represent counts (or another metric selected by the store) per hour 0...23.
struct HourHistogramData: Equatable {

    // MARK: - Identity / Input
    let tripType: TripType
    let from: Int64?
    let to: Int64?

    // MARK: - Raw Totals
    let values: [Double]
    let maxValue: Double

    // MARK: - Derived / Display
    let labels: [String]
    let valueTexts: [String]
    let normalized: [Double]

    // MARK: - Init (fetch + derive)
    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType
        self.from = from
        self.to = to

        let raw = try SegmentStore.shared.fetchStartHourHistogram(type: tripType, from: from, to: to)
        self.values = raw.values
        self.maxValue = raw.values.max() ?? 0

        // Labels and display text
        self.labels = (0..<24).map { "\($0)" }
        self.valueTexts = raw.values.map { Int($0) == 0 ? "0" : "\(Int($0))" }

        // Normalized for charts
        let denom = max(maxValue, 1)
        self.normalized = raw.values.map { $0 / denom }
    }
}
