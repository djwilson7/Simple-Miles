import Foundation
import CoreLocation

struct TripTotalsStore {
    var tripType: TripType
    
    /// Prefix string used for UserDefaults keys, derived from the tripType.
    var urlPrefix: String {
        return tripType.urlPrefix
    }
    
    /// Total distance of trips, stored in UserDefaults under "<urlPrefix>_totalDistance".
    var totalDistance: CLLocationDistance {
        get {
            return UserDefaults.standard.double(forKey: "\(urlPrefix)_totalDistance")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "\(urlPrefix)_totalDistance")
        }
    }
    
    /// Total duration of trips, stored in UserDefaults under "<urlPrefix>_totalDuration".
    var totalDuration: TimeInterval {
        get {
            return UserDefaults.standard.double(forKey: "\(urlPrefix)_totalDuration")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "\(urlPrefix)_totalDuration")
        }
    }
    
    /// Count of trips, stored in UserDefaults under "<urlPrefix>_tripCount".
    var tripCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: "\(urlPrefix)_tripCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "\(urlPrefix)_tripCount")
        }
    }
    
    /// Initializes the store with a specific TripType.
    /// - Parameter tripType: The type of trip to associate with this store.
    init(tripType: TripType) {
        // Initializing TripTotalsStore always updates its tripType to the passed-in value.
        self.tripType = tripType
    }
}
