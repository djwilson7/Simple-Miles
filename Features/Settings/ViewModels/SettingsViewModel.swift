import Foundation
import Combine
import CoreLocation

final class SettingsViewModel: ObservableObject {
    // MARK: - Backing Stores
    private var recordingStore: any RecordingSettingsProtocol {
        didSet { objectWillChange.send() }
    }
    private var displayStore: any DisplaySettingsProtocol {
        didSet { objectWillChange.send() }
    }
    private var exportStore: any ExportSettingsProtocol {
        didSet { objectWillChange.send() }
    }
    private var classificationStore: any ClassificationSettingsProtocol {
        didSet { objectWillChange.send() }
    }
    
    private var privacyStore: SettingsStoreProtocol {
        didSet { objectWillChange.send() }
    }


    // MARK: - Recording Bindings
    var motionSensitivity: MotionSensitivityLevel {
        get { recordingStore.motionSensitivity }
        set { recordingStore.motionSensitivity = newValue; objectWillChange.send() }
    }

    var pauseDuration: TimeInterval {
        get { recordingStore.pauseDuration }
        set { recordingStore.pauseDuration = newValue; objectWillChange.send() }
    }

    var minimumTripDistance: Double {
        get { recordingStore.minimumTripDistance }
        set { recordingStore.minimumTripDistance = newValue; objectWillChange.send() }
    }

    var baseSpeedThreshold: CLLocationSpeed {
        get { recordingStore.baseSpeedThreshold }
        set { recordingStore.baseSpeedThreshold = newValue; objectWillChange.send() }
    }

    var baseDistanceThreshold: CLLocationDistance {
        get { recordingStore.baseDistanceThreshold }
        set { recordingStore.baseDistanceThreshold = newValue; objectWillChange.send() }
    }

    // MARK: - Display Bindings
    var distanceUnit: DistanceUnit {
        get { displayStore.distanceUnit }
        set { displayStore.distanceUnit = newValue; objectWillChange.send() }
    }

    var timeFormat: TimeFormat {
        get { displayStore.timeFormat }
        set { displayStore.timeFormat = newValue; objectWillChange.send() }
    }

    var primaryColorTheme: ColorTheme {
        get { displayStore.primaryColorTheme }
        set { displayStore.primaryColorTheme = newValue; objectWillChange.send() }
    }

    var secondaryColorTheme: ColorTheme {
        get { displayStore.secondaryColorTheme }
        set { displayStore.secondaryColorTheme = newValue; objectWillChange.send() }
    }

    // MARK: - Export Bindings
    var includeRawCoordinates: Bool {
        get { exportStore.includeRawCoordinates }
        set { exportStore.includeRawCoordinates = newValue; objectWillChange.send() }
    }

    var exportFieldOptions: Set<ExportField> {
        get { exportStore.exportFieldOptions }
        set { exportStore.exportFieldOptions = newValue; objectWillChange.send() }
    }

    var defaultExportFileNamePrefix: String {
        get { exportStore.defaultExportFileNamePrefix }
        set { exportStore.defaultExportFileNamePrefix = newValue; objectWillChange.send() }
    }

    // MARK: - Classification Bindings
    var defaultTripType: TripType {
        get { classificationStore.defaultTripType }
        set { classificationStore.defaultTripType = newValue; objectWillChange.send() }
    }

    var businessModeEnabled: Bool {
        get { classificationStore.businessModeEnabled }
        set { classificationStore.businessModeEnabled = newValue; objectWillChange.send() }
    }

    var useProbabilisticTagging: Bool {
        get { classificationStore.useProbabilisticTagging }
        set { classificationStore.useProbabilisticTagging = newValue; objectWillChange.send() }
    }

    var classificationMode: ClassificationMode {
        get { classificationStore.classificationMode }
        set { classificationStore.classificationMode = newValue; objectWillChange.send() }
    }

    var customLabels: [String] {
        get { classificationStore.customLabels }
        set { classificationStore.customLabels = newValue; objectWillChange.send() }
    }
    
    var privacyConsentLevel: PrivacyConsentLevel {
        get { privacyStore.privacyConsentLevel }
        set { privacyStore.privacyConsentLevel = newValue; objectWillChange.send() }
    }


    // MARK: - Init
    init(
        recording: any RecordingSettingsProtocol = RecordingSettings(store: SettingsStore.shared),
        display: any DisplaySettingsProtocol = DisplaySettings(store: SettingsStore.shared),
        export: any ExportSettingsProtocol = ExportSettings(store: SettingsStore.shared),
        classification: any ClassificationSettingsProtocol = ClassificationSettings(store: SettingsStore.shared),
        privacy: SettingsStoreProtocol = SettingsStore.shared
    ) {
        self.recordingStore = recording
        self.displayStore = display
        self.exportStore = export
        self.classificationStore = classification
        self.privacyStore = privacy
    }

}
