import Foundation
import CoreLocation

/// Domain model representing a single location sample.
/// - Units:
///   - latitude/longitude in degrees (WGS84)
///   - speed in meters per second (m/s)
///   - course in degrees [0, 360); -1 indicates invalid/unknown from Core Location
///   - timestamp in absolute Date (UTC)
public struct LocationPoint: Equatable, Hashable, Codable, Sendable {

    // MARK: - Stored Properties (canonical units)
    /// Geographic coordinate in degrees (WGS84).
    public let coordinate: CLLocationCoordinate2D
    /// Sample timestamp (UTC).
    public let timestamp: Date
    /// Speed in meters per second (m/s). Non-negative; invalid Core Location speeds are clamped to 0.
    public let speed: CLLocationSpeed
    /// Course in degrees [0, 360). May be -1 when unknown from Core Location.
    public let course: CLLocationDirection

    // MARK: - Init
    /// Initialize from a Core Location CLLocation, normalizing certain values:
    /// - speed is clamped to [0, +∞) to avoid negative invalid readings
    public init(_ location: CLLocation) {
        self.coordinate = location.coordinate
        self.timestamp = location.timestamp
        self.speed = max(location.speed, 0) // normalize invalid negative speeds
        self.course = location.course
        precondition(Self.isValidLatitude(coordinate.latitude), "Latitude must be in [-90, 90]")
        precondition(Self.isValidLongitude(coordinate.longitude), "Longitude must be in [-180, 180]")
    }

    /// Designated initializer with explicit fields.
    /// - Parameters:
    ///   - coordinate: WGS84 coordinate
    ///   - timestamp: absolute date (UTC)
    ///   - speed: meters per second (m/s); will be clamped to [0, +∞)
    ///   - course: degrees [0, 360); may be -1 to indicate unknown
    public init(
        coordinate: CLLocationCoordinate2D,
        timestamp: Date,
        speed: CLLocationSpeed,
        course: CLLocationDirection
    ) {
        precondition(Self.isValidLatitude(coordinate.latitude), "Latitude must be in [-90, 90]")
        precondition(Self.isValidLongitude(coordinate.longitude), "Longitude must be in [-180, 180]")
        self.coordinate = coordinate
        self.timestamp = timestamp
        self.speed = max(speed, 0) // normalize invalid negative speeds
        self.course = course
    }

    // MARK: - Computed / Derived
    /// Convenience accessors for readability.
    public var latitude: CLLocationDegrees { coordinate.latitude }
    public var longitude: CLLocationDegrees { coordinate.longitude }

    // MARK: - Domain Methods (pure)
    /// Haversine distance to another point in meters.
    public func distance(to other: LocationPoint) -> CLLocationDistance {
        let locationSelf = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let locationOther = CLLocation(latitude: other.coordinate.latitude, longitude: other.coordinate.longitude)
        return locationSelf.distance(from: locationOther)
    }

    // MARK: - Equatable
    /// Equality is defined by exact coordinate match (latitude & longitude).
    /// Timestamp and motion parameters are intentionally ignored.
    public static func == (lhs: LocationPoint, rhs: LocationPoint) -> Bool {
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }

    // MARK: - Codable
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
        precondition(Self.isValidLatitude(latitude), "Latitude must be in [-90, 90]")
        precondition(Self.isValidLongitude(longitude), "Longitude must be in [-180, 180]")

        self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        let decodedSpeed = try container.decode(CLLocationSpeed.self, forKey: .speed)
        self.speed = max(decodedSpeed, 0) // normalize invalid negative speeds
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

    // MARK: - Validation Helpers
    @inline(__always)
    private static func isValidLatitude(_ lat: CLLocationDegrees) -> Bool {
        lat >= -90 && lat <= 90
    }

    @inline(__always)
    private static func isValidLongitude(_ lon: CLLocationDegrees) -> Bool {
        lon >= -180 && lon <= 180
    }
}
