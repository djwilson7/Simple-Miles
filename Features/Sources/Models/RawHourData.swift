import Foundation

struct RawHourData {
    var values: [Double]

    init(values: [Double]) {
        precondition(values.count == 24)
        self.values = values
    }

    static var zero: RawHourData { RawHourData(values: Array(repeating: 0, count: 24)) }
}
