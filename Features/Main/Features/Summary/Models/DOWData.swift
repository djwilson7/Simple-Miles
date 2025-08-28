import Foundation

/// UI-ready Day-of-Week mileage data (for a given TripType and optional date range).
/// Built from RawDOWData (meters per weekday; 0=Sun … 6=Sat).
struct DOWData: Equatable {
    // MARK: Scope
    let tripType: TripType
    let from: Int64?
    let to: Int64?

    // MARK: Raw (from DAO)
    /// Meters per weekday, index 0=Sun … 6=Sat
    let meters: [Double]          // length == 7

    // MARK: Aggregates for rendering
    let totalMeters: Double
    let maxMeters: Double

    // MARK: UI-ready
    /// "Sun", "Mon", ..., "Sat" (matches SQLite %w order)
    let labels: [String]

    /// Normalized 0…1 heights for bars; safe when maxMeters == 0
    let normalizedHeights: [Double]

    /// Formatted strings for display (e.g., "123.4 mi")
    let valueTexts: [String]

    /// Optional total string (e.g., "344.9 mi total")
    let totalText: String

    /// Designated initializer: fetches raw buckets and converts to UI-ready fields.
    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType
        self.from = from
        self.to = to

        // 1) Pull raw DOW meters (Sun…Sat)
        let raw = try TripSegmentStore.shared.fetchDOWMeters(type: tripType)

        // 2) Copy raw payload
        self.meters = raw.meters
        self.totalMeters = raw.meters.reduce(0, +)
        self.maxMeters = raw.meters.max() ?? 0

        // 3) Labels (US-style, Sun-first; rotate if you later localize to Monday-first)
        self.labels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        // 4) Normalized heights (protect against divide-by-zero)
        let denom = maxMeters > 0 ? maxMeters : 1.0
        self.normalizedHeights = raw.meters.map { $0 / denom }

        // 5) UI strings (distance formatted per your utility)
        self.valueTexts = raw.meters.map { DistanceUtility.formatter(meters: $0) }
        self.totalText  = DistanceUtility.formatter(meters: totalMeters)
    }
}
