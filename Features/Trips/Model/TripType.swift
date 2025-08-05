import Foundation

public class TripType: Codable, Equatable, Hashable {
    public let name: String
    public let urlPrefix: String

    public init(name: String) {
        self.name = name
        self.urlPrefix = name + "_"
    }

    public static func == (lhs: TripType, rhs: TripType) -> Bool {
        return lhs.name == rhs.name && lhs.urlPrefix == rhs.urlPrefix
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(urlPrefix)
    }
}
