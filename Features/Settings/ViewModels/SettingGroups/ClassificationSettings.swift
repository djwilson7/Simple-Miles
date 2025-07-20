import Foundation

final class ClassificationSettings: ClassificationSettingsProtocol {
    @Published var defaultTripType: TripType
    @Published var businessModeEnabled: Bool
    @Published var useProbabilisticTagging: Bool
    @Published var classificationMode: ClassificationMode
    @Published var customLabels: [String]

    init(store: SettingsStoreProtocol) {
        self.defaultTripType = store.defaultTripType
        self.businessModeEnabled = store.businessModeEnabled
        self.useProbabilisticTagging = store.useProbabilisticTagging
        self.classificationMode = store.classificationMode
        self.customLabels = store.customLabels
    }
}
