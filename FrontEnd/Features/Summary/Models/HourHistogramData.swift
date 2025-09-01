import Foundation

struct HourHistogramData {
    let tripType: TripType
    let values: [Double]
    let maxValue: Double
    let labels: [String]
    let valueTexts: [String]
    let normalized: [Double]

    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType

        let raw = try SegmentStore.shared.fetchStartHourHistogram(type: tripType, from: from, to: to)
        self.values = raw.values
        self.maxValue = raw.values.max() ?? 0
        self.labels = (0..<24).map { "\($0)" }
        self.valueTexts = raw.values.map { Int($0) == 0 ? "0" : "\((Int($0)))" }
        let denom = max(maxValue, 1)
        self.normalized = raw.values.map { $0 / denom }
    }
}
