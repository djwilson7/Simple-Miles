import Foundation

struct DOWData: Equatable {
    let tripType: TripType
    let from: Int64?
    let to: Int64?
    let meters: [Double]
    let totalMeters: Double
    let maxMeters: Double
    let labels: [String]
    let normalizedHeights: [Double]
    let valueTexts: [String]
    let totalText: String

    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType
        self.from = from
        self.to = to

        let raw = try SegmentStore.shared.fetchDOWMeters(type: tripType)

        self.meters = raw.meters
        self.totalMeters = raw.meters.reduce(0, +)
        self.maxMeters = raw.meters.max() ?? 0

        self.labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        let denom = maxMeters > 0 ? maxMeters : 1.0
        self.normalizedHeights = raw.meters.map { $0 / denom }

        self.valueTexts = raw.meters.map { DistanceUtility.formatter(meters: $0) }
        self.totalText  = DistanceUtility.formatter(meters: totalMeters)
    }
}
