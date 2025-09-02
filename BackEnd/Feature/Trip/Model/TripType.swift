import Foundation

/// Classification of a trip for organization and export.
enum TripType: String, Codable, Hashable, CaseIterable {

    // MARK: - Cases
    case personal
    case business
    case custom
    case unsorted
    case trash

    // MARK: - Computed (Domain)
    var name: String { rawValue }

    /// URL/export prefix derived from the name.
    var urlPrefix: String {
        return self.name + "_"
    }

    /// Integer value used for database/storage.
    var dbValue: Int {
        switch self {
        case .personal: return 0
        case .business: return 1
        case .custom: return 2
        case .unsorted: return 3
        case .trash: return 4
        }
    }

    // MARK: - Init (Mapping)
    /// Initializes from a database integer value.
    init?(dbValue: Int) {
        switch dbValue {
        case 0: self = .personal
        case 1: self = .business
        case 2: self = .custom
        case 3: self = .unsorted
        case 4: self = .trash
        default: return nil
        }
    }
}
