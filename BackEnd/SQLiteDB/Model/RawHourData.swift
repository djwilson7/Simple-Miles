import Foundation

/// Raw values bucketed per hour of day (0…23).
/// - Units:
///   - values: domain-defined (e.g., meters, counts) per hour
struct RawHourData {

    // MARK: - Stored Properties (canonical units)
    /// Values per hour of day (0…23). Must contain exactly 24 entries.
    var values: [Double]

    // MARK: - Init (validation)
    init(values: [Double]) {
        precondition(values.count == 24)
        self.values = values
    }

    // MARK: - Fixtures / Defaults
    /// Zero-initialized values for all 24 hours.
    static var zero: RawHourData { RawHourData(values: Array(repeating: 0, count: 24)) }
}
