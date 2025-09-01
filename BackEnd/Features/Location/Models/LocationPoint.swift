import Foundation
import CoreLocation

public struct LocationPoint: Equatable, Codable {
    public let coordinate: CLLocationCoordinate2D
    public let timestamp: Date
    public let speed: CLLocationSpeed
    public let course: CLLocationDirection

    public init(_ location: CLLocation) {
        self.coordinate = location.coordinate
        self.timestamp = location.timestamp
        self.speed = location.speed
        self.course = location.course
    }

    public static func == (lhs: LocationPoint, rhs: LocationPoint) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case timestamp
        case speed
        case course
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.speed = try container.decode(CLLocationSpeed.self, forKey: .speed)
        self.course = try container.decode(CLLocationDirection.self, forKey: .course)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(speed, forKey: .speed)
        try container.encode(course, forKey: .course)
    }

    public func distance(to other: LocationPoint) -> CLLocationDistance {
        let locationSelf = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let locationOther = CLLocation(latitude: other.coordinate.latitude, longitude: other.coordinate.longitude)
        return locationSelf.distance(from: locationOther)
    }
}
