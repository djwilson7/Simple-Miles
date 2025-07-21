// MARK: - LastKnownLocationStore.swift

import Foundation
import CoreLocation

final class LastKnownLocationStore {
    private let key = "lastKnownLocation"
    private var cachedLocation: CLLocation?

    func update(_ location: CLLocation) {
        cachedLocation = location
    }

    func persist() {
        guard let location = cachedLocation else { return }
        let dict = [
            "lat": location.coordinate.latitude,
            "lon": location.coordinate.longitude,
            "timestamp": location.timestamp.timeIntervalSince1970
        ]
        UserDefaults.standard.set(dict, forKey: key)
    }

    func load() -> CLLocation? {
        guard
            let dict = UserDefaults.standard.dictionary(forKey: key),
            let lat = dict["lat"] as? CLLocationDegrees,
            let lon = dict["lon"] as? CLLocationDegrees,
            let time = dict["timestamp"] as? TimeInterval
        else { return nil }

        let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let timestamp = Date(timeIntervalSince1970: time)
        return CLLocation(coordinate: coord, altitude: 0, horizontalAccuracy: 1, verticalAccuracy: 1, timestamp: timestamp)
    }

    var latestLocation: CLLocation? {
        return cachedLocation ?? load()
    }
}
