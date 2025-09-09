import Foundation
import CoreLocation

/// Represents a contiguous segment of a trip with sampled location points,
/// accumulated distance, and duration. Distances are in meters; durations in seconds.
public struct TripSegment {

    // MARK: - Identity
    public let id: UUID

    // MARK: - Stored Properties
    public var startTimestamp: Date
    public var endTimestamp: Date?
    public var pathCoordinates: [LocationPoint]
    public var distance: CLLocationDistance
    public var duration: TimeInterval
    internal var tripType: TripType

    // MARK: - Init
    public init(startTimestamp: Date) {
        self.id = UUID()
        self.startTimestamp = startTimestamp
        self.endTimestamp = nil
        self.pathCoordinates = []
        self.distance = 0
        self.duration = 0
        self.tripType = .unsorted
    }

    // MARK: - Computed
    /// Database-friendly identifier string.
    public var dbID: String { id.uuidString }

    // MARK: - Domain Methods
    /// Marks the segment as finished and computes duration from the start time.
    public mutating func finalize(at endTimestamp: Date) {
        self.endTimestamp = endTimestamp
        self.duration = endTimestamp.timeIntervalSince(startTimestamp)
    }

    /// Appends a new location point and updates cumulative distance.
    public mutating func append(location: LocationPoint) {
        pathCoordinates.append(location)
        if let lastLocation = pathCoordinates.dropLast().last {
            distance += lastLocation.distance(to: location)
        }
    }

    /// Merges another segment's path, distance, and duration into this segment.
    public mutating func merge(with other: TripSegment) {
        self.append(segment: other)
    }

    // MARK: - Helpers
    private mutating func append(segment: TripSegment) {
        self.pathCoordinates += segment.pathCoordinates
        self.distance += segment.distance
        self.duration += segment.duration
    }
}
