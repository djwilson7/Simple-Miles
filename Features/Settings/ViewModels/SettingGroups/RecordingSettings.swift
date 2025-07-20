import Foundation
import CoreLocation

final class RecordingSettings: RecordingSettingsProtocol {
    @Published var motionSensitivity: MotionSensitivityLevel
    @Published var pauseDuration: TimeInterval
    @Published var minimumTripDistance: Double
    @Published var baseSpeedThreshold: CLLocationSpeed
    @Published var baseDistanceThreshold: CLLocationDistance

    init(store: SettingsStoreProtocol) {
        self.motionSensitivity = store.motionSensitivity
        self.pauseDuration = store.pauseDuration
        self.minimumTripDistance = store.minimumTripDistance
        self.baseSpeedThreshold = store.baseSpeedThreshold
        self.baseDistanceThreshold = store.baseDistanceThreshold
    }
}
