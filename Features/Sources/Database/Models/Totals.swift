//
//  Totals.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/19/25.
//

import Foundation

/// Aggregated metrics for a set of trips (e.g., by type or for the home page).
/// Distances are stored in meters; durations in seconds.
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

    /// Empty totals convenience value.
    public static let empty = Totals()

    /// Combine two Totals (e.g., merging pages or multiple types).
    public func adding(_ other: Totals) -> Totals {
        Totals(totalDistanceM: totalDistanceM + other.totalDistanceM,
               totalDurationS: totalDurationS + other.totalDurationS,
               tripCount: tripCount + other.tripCount)
    }

    // MARK: - Convenience computed values

    /// Duration as TimeInterval (seconds).
    public var duration: TimeInterval { totalDurationS }
    /// Whether there are no trips represented.
    public var isEmpty: Bool { tripCount == 0 }
}
