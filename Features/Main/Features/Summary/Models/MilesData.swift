import Foundation

struct MilesData {
    /// The trip type this data is scoped to
    let tripType: TripType
    
    
    var typeMiles: Double   // meters for this trip type
    var totalMiles: Double  // meters for all trips (excluding unclassified/trash)
    var ratioPct: Double
    var ratioPctTxt: String
    var outOfTxt: String

    /// Designated initializer that loads data immediately.
    /// - Parameters:
    ///   - tripType: TripType to scope the type-specific total
    ///   - from: Optional epoch seconds lower bound (inclusive)
    ///   - to:   Optional epoch seconds upper bound (inclusive)
    init(tripType: TripType, from: Int64? = nil, to: Int64? = nil) throws {
        self.tripType = tripType
        let result = try TripSegmentStore.shared.fetchMilesData(type: tripType, from: from, to: to)
        Log("Total Miles: \(result.totalMeters) Trip Miles: \(result.typeMeters)")
        self.typeMiles = result.typeMeters
        self.totalMiles = result.totalMeters
        self.ratioPct = totalMiles > 0 ? (typeMiles / totalMiles) * 100 : 0
        self.ratioPctTxt = String(format: "%.1f%%", ratioPct)
        self.outOfTxt = "\(Int(typeMiles)) / \(Int(totalMiles))"
    }

}
