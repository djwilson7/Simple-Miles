import Foundation

struct RawDOWData {
    var meters: [Double]

    init(meters: [Double]) {
        precondition(meters.count == 7, "RawDOWData must have 7 entries (Sun…Sat)")
        self.meters = meters
    }

    static var zero: RawDOWData {
        RawDOWData(meters: Array(repeating: 0.0, count: 7))
    }
}
