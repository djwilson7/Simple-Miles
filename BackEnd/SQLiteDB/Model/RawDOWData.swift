import Foundation

/// Raw distance totals per day of week (Sun…Sat).
/// - Units:
///   - meters: meters per day (array count must be 7)
struct RawDOWData {

    // MARK: - Stored Properties (canonical units)
    /// Distances per day of week starting on Sunday.
    var meters: [Double]

    // MARK: - Init (validation)
    init(meters: [Double]) {
        precondition(meters.count == 7, "RawDOWData must have 7 entries (Sun…Sat)")
        self.meters = meters
    }

    // MARK: - Fixtures / Defaults
    /// Zero-initialized distances for all days (Sun…Sat).
    static var zero: RawDOWData {
        RawDOWData(meters: Array(repeating: 0.0, count: 7))
    }
}
