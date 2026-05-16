import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    /// Returns the bearing (0-360) from this coordinate to another.
    public func bearing(to other: CLLocationCoordinate2D) -> Double {
        let lat1 = self.latitude * .pi / 180
        let lon1 = self.longitude * .pi / 180
        let lat2 = other.latitude * .pi / 180
        let lon2 = other.longitude * .pi / 180

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)

        return (radiansBearing * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
    }

    /// Calculates a coordinate at a specific distance and bearing from this coordinate.
    public func coordinate(at distance: CLLocationDistance, bearing: CLLocationDirection) -> CLLocationCoordinate2D {
        let radius = 6_371_000.0 // Earth's radius in meters
        let δ = distance / radius
        let θ = bearing * .pi / 180
        let φ1 = latitude * .pi / 180
        let λ1 = longitude * .pi / 180

        let φ2 = asin(sin(φ1) * cos(δ) + cos(φ1) * sin(δ) * cos(θ))
        let λ2 = λ1 + atan2(sin(θ) * sin(δ) * cos(φ1), cos(δ) - sin(φ1) * sin(φ2))

        return CLLocationCoordinate2D(
            latitude: φ2 * 180 / .pi,
            longitude: λ2 * 180 / .pi
        )
    }
}
