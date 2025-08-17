import Foundation
import CoreLocation

public struct TripSegment: Codable {
    public let id: UUID
    public var startTimestamp: Date
    public var endTimestamp: Date?
    public var pathCoordinates: [LocationPoint]
    public var distance: CLLocationDistance
    public var duration: TimeInterval
    public var headingSamples: [CLLocationDirection]
    public var speedSamples: [CLLocationSpeed]
    public var tripType: TripType
    
    // Added fileName property to hold file name, initialized to "temp_trip" on init, updated on finalize
    public private(set) var fileName: String = "temp_trip"
    
    private enum CodingKeys: String, CodingKey {
        case id, startTimestamp, endTimestamp, pathCoordinates, distance, duration, headingSamples, speedSamples, tripType, fileName
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTimestamp = try container.decode(Date.self, forKey: .startTimestamp)
        endTimestamp = try container.decodeIfPresent(Date.self, forKey: .endTimestamp)
        distance = try container.decode(CLLocationDistance.self, forKey: .distance)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        headingSamples = try container.decode([CLLocationDirection].self, forKey: .headingSamples)
        speedSamples = try container.decode([CLLocationSpeed].self, forKey: .speedSamples)
        tripType = try container.decode(TripType.self, forKey: .tripType)
        pathCoordinates = try container.decode([LocationPoint].self, forKey: .pathCoordinates)
        self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? "temp_trip"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTimestamp, forKey: .startTimestamp)
        try container.encode(endTimestamp, forKey: .endTimestamp)
        try container.encode(distance, forKey: .distance)
        try container.encode(duration, forKey: .duration)
        try container.encode(headingSamples, forKey: .headingSamples)
        try container.encode(speedSamples, forKey: .speedSamples)
        try container.encode(tripType, forKey: .tripType)
        try container.encode(pathCoordinates, forKey: .pathCoordinates)
        try container.encode(fileName, forKey: .fileName)
    }
    
    // Computed property to suggest a file name based on trip data
    private var suggestedFileName: String {
        // Example file name format: "trip_YYYYMMdd_HHmmss"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return "\(self.tripType.urlPrefix)\(formatter.string(from: startTimestamp))"
    }
    
    // Updates the fileName property
    private mutating func updateFileName(_ newName: String) {
        self.fileName = newName
    }
    
    
    
    // Updated init to set fileName to "temp_trip" during construction
    public init(
        startTimestamp: Date,
        tripType: TripType = TripType(name: "unclassified")
    ) {
        self.id = UUID()
        self.startTimestamp = startTimestamp
        self.pathCoordinates = []
        self.distance = 0
        self.duration = 0
        self.headingSamples = []
        self.speedSamples = []
        self.tripType = tripType
        self.fileName = "temp_trip"
    }
    
    public mutating func resortSegment(as newType: TripType) {
        self.tripType = newType
        updateFileName(suggestedFileName) // Now uses the new tripType’s prefix
    }
    
    public mutating func finalize(at endTimestamp: Date) {
        print("TripSegment Finalize called with endTimestamp: \(endTimestamp)")
        self.endTimestamp = endTimestamp
        self.duration = endTimestamp.timeIntervalSince(startTimestamp)
        updateFileName(suggestedFileName)
    }
    
    public mutating func append(location: LocationPoint) {
        print("TripSegment Append called with location: \(location.coordinate)")
        pathCoordinates.append(location)
        headingSamples.append(location.course)
        speedSamples.append(location.speed)
        if let lastLocation = pathCoordinates.dropLast().last {
            distance += lastLocation.distance(to: location)
        }
    }
    
    private mutating func append(segment: TripSegment) {
        self.pathCoordinates += segment.pathCoordinates
        self.headingSamples += segment.headingSamples
        self.speedSamples += segment.speedSamples
        self.distance += segment.distance
        self.duration += segment.duration
    }
    
    public mutating func merge(with other: TripSegment) {
        self.append(segment: other)
    }
}
