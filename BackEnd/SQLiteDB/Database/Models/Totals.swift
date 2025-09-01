import Foundation

public struct Totals: Equatable, Codable {
    public let totalDistanceM: Double
    public let totalDurationS: Double
    public let tripCount: Int

    public init(totalDistanceM: Double = 0,
                totalDurationS: Double = 0,
                tripCount: Int = 0) {
        self.totalDistanceM = totalDistanceM
        self.totalDurationS = totalDurationS
        self.tripCount = tripCount
    }

    public static let empty = Totals()

    public func adding(_ other: Totals) -> Totals {
        Totals(totalDistanceM: totalDistanceM + other.totalDistanceM,
               totalDurationS: totalDurationS + other.totalDurationS,
               tripCount: tripCount + other.tripCount)
    }

    public var duration: TimeInterval { totalDurationS }
    public var isEmpty: Bool { tripCount == 0 }
}
