import Foundation
import CoreLocation

final class CameraDistance {
    static let shared = CameraDistance()
    private let storageKey = "cameraAltitude"
    
    private init() {}

    /// Save the camera distance value to persistent storage.
    /// - Parameter distance: The camera distance to save.
    func saveDistance(_ distance: CLLocationDistance) {
        UserDefaults.standard.set(distance, forKey: storageKey)
    }

    /// Load the camera distance value from persistent storage.
    /// - Returns: The saved camera distance if available, otherwise nil.
    func loadDistance() -> CLLocationDistance? {
        let value = UserDefaults.standard.double(forKey: storageKey)
        return value > 0 ? value : nil
    }
}
