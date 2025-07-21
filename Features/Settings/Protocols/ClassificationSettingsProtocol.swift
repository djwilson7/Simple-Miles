import Foundation

enum ClassificationMode: String, CaseIterable, CustomStringConvertible {
    case accumulate
    case manual
    case automatic
    
    var description: String {
        switch self{
        case .accumulate: "Sort all trips later."
        case .manual: "You sort the trips."
        case .automatic: "The app sorts the trips."
        }
    }
}

protocol ClassificationSettingsProtocol: ObservableObject {
    var defaultTripType: TripType { get set }
    var businessModeEnabled: Bool { get set }
    var useProbabilisticTagging: Bool { get set }
    var classificationMode: ClassificationMode { get set }
    var customLabels: [String] { get set }
}
