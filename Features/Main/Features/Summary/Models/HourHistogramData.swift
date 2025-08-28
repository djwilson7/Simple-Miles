import Foundation

struct HourHistogramData {
    let tripType: TripType
    let values: [Double]          // 24
    let maxValue: Double
    let labels: [String]          // "0", "1", … "23" or "12a/1a…"
    let valueTexts: [String]      // formatted per metric
    let normalized: [Double]      // 0…1 heights

    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType

        let raw = try TripSegmentStore.shared.fetchStartHourHistogram(type: tripType, from: from, to: to)
        self.values = raw.values
        self.maxValue = raw.values.max() ?? 0

        // Labels (24h). If you prefer 12h: map 0→"12a", 13→"1p", etc.
        self.labels = (0..<24).map { "\($0)" }

        self.valueTexts = raw.values.map { Int($0) == 0 ? "0" : "\((Int($0)))" }
      

        let denom = max(maxValue, 1)
        self.normalized = raw.values.map { $0 / denom }
    }
}
