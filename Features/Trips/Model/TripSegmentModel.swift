import Foundation
import CoreLocation

struct TripSegment: Codable {
    let id: UUID
    var startTimestamp: Date
    var endTimestamp: Date?
    var pathCoordinates: [CLLocationCoordinate2D]
    var distance: CLLocationDistance
    var duration: TimeInterval
    var headingSamples: [CLLocationDirection]
    var speedSamples: [CLLocationSpeed]
    var tripType: TripType
    
    // Added fileName property to hold file name, initialized to "temp_trip" on init, updated on finalize
    private(set) var fileName: String = "temp_trip"
    
    private enum CodingKeys: String, CodingKey {
        case id, startTimestamp, endTimestamp, pathCoordinates, distance, duration, headingSamples, speedSamples, tripType, fileName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startTimestamp = try container.decode(Date.self, forKey: .startTimestamp)
        endTimestamp = try container.decodeIfPresent(Date.self, forKey: .endTimestamp)
        distance = try container.decode(CLLocationDistance.self, forKey: .distance)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        headingSamples = try container.decode([CLLocationDirection].self, forKey: .headingSamples)
        speedSamples = try container.decode([CLLocationSpeed].self, forKey: .speedSamples)
        tripType = try container.decode(TripType.self, forKey: .tripType)
        let rawCoords = try container.decode([[Double]].self, forKey: .pathCoordinates)
        pathCoordinates = rawCoords.map { CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]) }
        self.fileName = try container.decodeIfPresent(String.self, forKey: .fileName) ?? "temp_trip"
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(startTimestamp, forKey: .startTimestamp)
        try container.encode(endTimestamp, forKey: .endTimestamp)
        try container.encode(distance, forKey: .distance)
        try container.encode(duration, forKey: .duration)
        try container.encode(headingSamples, forKey: .headingSamples)
        try container.encode(speedSamples, forKey: .speedSamples)
        try container.encode(tripType, forKey: .tripType)
        let rawCoords = pathCoordinates.map { [$0.latitude, $0.longitude] }
        try container.encode(rawCoords, forKey: .pathCoordinates)
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
    init(
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
    
    mutating func resortSegment(as newType: TripType) {
        self.tripType = newType
        updateFileName(suggestedFileName) // Now uses the new tripType’s prefix
    }
    
    mutating func finalize(at endTimestamp: Date) {
        print("TripSegment Finalize called with endTimestamp: \(endTimestamp)")
        self.endTimestamp = endTimestamp
        self.duration = endTimestamp.timeIntervalSince(startTimestamp)
        updateFileName(suggestedFileName)
    }
    
    mutating func append(location: CLLocation) {
        print("TripSegment Append called with location: \(location.coordinate)")
        pathCoordinates.append(location.coordinate)
        headingSamples.append(location.course)
        speedSamples.append(location.speed)
        if let lastLocation = pathCoordinates.dropLast().last {
            let previous = CLLocation(latitude: lastLocation.latitude, longitude: lastLocation.longitude)
            distance += previous.distance(from: location)
        }
    }
    
    private mutating func append(segment: TripSegment) {
        print("TripSegment Append Segment called with segment id: \(segment.id)")
        self.pathCoordinates += segment.pathCoordinates
        self.headingSamples += segment.headingSamples
        self.speedSamples += segment.speedSamples
        self.distance += segment.distance
        self.duration += segment.duration
    }

    static func merge(liveSegment: TripSegment, previousSegment: TripSegment) -> TripSegment {
        print("TripSegment Merge called with liveSegment id: \(liveSegment.id), previousSegment id: \(previousSegment.id)")
        var mergedSegment = previousSegment
        mergedSegment.append(segment: liveSegment)
        return mergedSegment
    }
}
