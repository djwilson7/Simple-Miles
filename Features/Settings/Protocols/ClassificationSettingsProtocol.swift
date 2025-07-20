import Foundation

enum ClassificationMode: String, CaseIterable {
    case accumulate
    case manual
    case automatic
}

protocol ClassificationSettingsProtocol: ObservableObject {
    var defaultTripType: TripType { get set }
    var businessModeEnabled: Bool { get set }
    var useProbabilisticTagging: Bool { get set }
    var classificationMode: ClassificationMode { get set }
    var customLabels: [String] { get set }
}
