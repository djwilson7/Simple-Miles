import Foundation
import CoreLocation

public struct TripSegment {
    public let id: UUID
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

//    // MARK: - Mutations
//    mutating func resortSegment(as newType: TripType) {
//        self.tripType = newType
//    }

    public mutating func finalize(at endTimestamp: Date) {
        self.endTimestamp = endTimestamp
        self.duration = endTimestamp.timeIntervalSince(startTimestamp)
    }

    public mutating func append(location: LocationPoint) {
        // Append point and update incremental distance
        pathCoordinates.append(location)
        if let lastLocation = pathCoordinates.dropLast().last {
            distance += lastLocation.distance(to: location)
        }
    }

    private mutating func append(segment: TripSegment) {
        self.pathCoordinates += segment.pathCoordinates
        self.distance += segment.distance
        self.duration += segment.duration
    }

    public mutating func merge(with other: TripSegment) {
        self.append(segment: other)
    }

    // Canonical database identifier (UUID string)
    public var dbID: String { id.uuidString }
}
