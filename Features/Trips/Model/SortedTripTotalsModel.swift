import Foundation
import CoreLocation

struct SortedTripTotalsModel: Codable, Equatable {
    let tripType: TripType
    let urlPrefix: String
    
    private(set) var totalDistance: CLLocationDistance
    private(set) var totalDuration: TimeInterval
    private(set) var tripCount: Int
    
    private var totalsStore: TripTotalsStore
    
    init(tripType: TripType) {
        self.tripType = tripType
        self.totalsStore = TripTotalsStore(tripType: tripType)
        self.totalDistance = totalsStore.totalDistance
        self.totalDuration = totalsStore.totalDuration
        self.tripCount = totalsStore.tripCount
        self.urlPrefix = tripType.urlPrefix
    }
    
    internal mutating func addTrip(tripSegment: inout TripSegment) {
        tripSegment.tripType = self.tripType
        totalsStore.totalDistance += tripSegment.distance
        totalsStore.totalDuration += tripSegment.duration
        totalsStore.tripCount += 1
        
        totalDistance = totalsStore.totalDistance
        totalDuration = totalsStore.totalDuration
        tripCount = totalsStore.tripCount
    }
    
    internal mutating func removeTrip(tripSegment: inout TripSegment) {
        guard tripSegment.distance > 0, tripSegment.duration > 0 else {
            return
        }
        totalsStore.totalDistance -= tripSegment.distance
        totalsStore.totalDuration -= tripSegment.duration
        totalsStore.totalDistance = max(0, totalsStore.totalDistance)
        totalsStore.totalDuration = max(0, totalsStore.totalDuration)
        totalsStore.tripCount = max(totalsStore.tripCount - 1, 0)
        
        totalDistance = totalsStore.totalDistance
        totalDuration = totalsStore.totalDuration
        tripCount = totalsStore.tripCount
        
        tripSegment.tripType = TripType(name: "unclassified")
    }
    
    private enum CodingKeys: String, CodingKey {
        case tripType
        case urlPrefix
        case totalDistance
        case totalDuration
        case tripCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tripType = try container.decode(TripType.self, forKey: .tripType)
        self.tripType = tripType
        self.urlPrefix = try container.decode(String.self, forKey: .urlPrefix)
        self.totalDistance = try container.decode(CLLocationDistance.self, forKey: .totalDistance)
        self.totalDuration = try container.decode(TimeInterval.self, forKey: .totalDuration)
        self.tripCount = try container.decode(Int.self, forKey: .tripCount)
        self.totalsStore = TripTotalsStore(tripType: tripType)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tripType, forKey: .tripType)
        try container.encode(urlPrefix, forKey: .urlPrefix)
        try container.encode(totalDistance, forKey: .totalDistance)
        try container.encode(totalDuration, forKey: .totalDuration)
        try container.encode(tripCount, forKey: .tripCount)
    }
    
    static func == (lhs: SortedTripTotalsModel, rhs: SortedTripTotalsModel) -> Bool {
        return lhs.tripType == rhs.tripType &&
            lhs.urlPrefix == rhs.urlPrefix &&
            lhs.totalDistance == rhs.totalDistance &&
            lhs.totalDuration == rhs.totalDuration &&
            lhs.tripCount == rhs.tripCount
    }
}
