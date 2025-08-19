import Foundation

enum TripType: String, Codable, Hashable, CaseIterable {
    case personal
    case business
    case custom
    case unclassified
    
    var name: String { rawValue }
    
    var urlPrefix: String {
        return self.name + "_"
    }
}
