import Foundation

enum TripType: String, Codable, Hashable, CaseIterable {
    case personal
    case business
    case custom
    case unsorted
    
    var name: String { rawValue }
    
    var urlPrefix: String {
        return self.name + "_"
    }
    
    var dbValue: Int {
        switch self {
        case .personal: return 0
        case .business: return 1
        case .custom: return 2
        case .unsorted: return 3
        }
    }
    
    init?(dbValue: Int) {
        switch dbValue {
        case 0: self = .personal
        case 1: self = .business
        case 2: self = .custom
        case 3: self = .unsorted
        default: return nil
        }
    }
}
