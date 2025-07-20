import Foundation
import CoreLocation

protocol RecordingSettingsProtocol: ObservableObject {
    var motionSensitivity: MotionSensitivityLevel { get set }
    var pauseDuration: TimeInterval { get set }
    var minimumTripDistance: Double { get set }
    var baseSpeedThreshold: CLLocationSpeed { get set }
    var baseDistanceThreshold: CLLocationDistance { get set }
}
