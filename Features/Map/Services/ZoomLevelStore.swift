import Foundation
import MapKit

final class ZoomLevelStore {
    private let storageKey = "com.simplemiles.zoomLevel"
    private let altitudeKey = "com.simplemiles.zoomAltitude"
    private var inMemoryRegion: MKCoordinateRegion?

    func save(region: MKCoordinateRegion) {
        inMemoryRegion = region
        let dict: [String: CLLocationDegrees] = [
            "lat": region.center.latitude,
            "lon": region.center.longitude,
            "latDelta": region.span.latitudeDelta,
            "lonDelta": region.span.longitudeDelta
        ]
        UserDefaults.standard.set(dict, forKey: storageKey)
    }

    func load() -> MKCoordinateRegion? {
        if let region = inMemoryRegion { return region }

        guard let dict = UserDefaults.standard.dictionary(forKey: storageKey),
              let lat = dict["lat"] as? CLLocationDegrees,
              let lon = dict["lon"] as? CLLocationDegrees,
              let latDelta = dict["latDelta"] as? CLLocationDegrees,
              let lonDelta = dict["lonDelta"] as? CLLocationDegrees
        else { return nil }

        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    func save(altitude: CLLocationDistance) {
        UserDefaults.standard.set(altitude, forKey: altitudeKey)
    }

    func loadAltitude() -> CLLocationDistance? {
        let value = UserDefaults.standard.double(forKey: altitudeKey)
        return value > 0 ? value : nil
    }

    func clear() {
        inMemoryRegion = nil
        UserDefaults.standard.removeObject(forKey: storageKey)
        UserDefaults.standard.removeObject(forKey: altitudeKey)
    }
}
