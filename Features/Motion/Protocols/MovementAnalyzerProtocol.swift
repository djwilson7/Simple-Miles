import Foundation
import CoreLocation

protocol MovementAnalyzerProtocol {
    var startTripAccelerationThreshold: Double { get set }
    var endTripAccelerationThreshold: Double { get set }
    var startSpeedThreshold: CLLocationSpeed { get set }
    var pauseSpeedThreshold: CLLocationSpeed { get set }

    func shouldPreemptivelyMonitor(accelerations: [Double]) -> Bool
    func shouldStartRecording(speeds: [CLLocationSpeed], accelerations: [Double]) -> Bool
    func shouldPause(accelerations: [Double], currentLocation: CLLocation?) -> Bool
    func shouldResume(accelerations: [Double], previousLocation: CLLocation?) -> Bool
}
