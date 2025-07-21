import Foundation
import CoreLocation

struct MovementAnalyzer: MovementAnalyzerProtocol {
    // MARK: - Tunable Thresholds
    var startTripAccelerationThreshold: Double = 0.05
    var endTripAccelerationThreshold: Double = 0.02
    var startSpeedThreshold: CLLocationSpeed = 2.24  // ~5mph
    var pauseSpeedThreshold: CLLocationSpeed = 2.24
    var sustainedAccelerationDuration: TimeInterval = 3.0
    var sustainedSpeedDuration: TimeInterval = 5.0
    var stationaryRadius: CLLocationDistance = 15.0
    var requiredPauseDuration: TimeInterval = 10.0

    // MARK: - Phase 1: Acceleration Detection
    func shouldPreemptivelyMonitor(accelerations: [Double]) -> Bool {
        let spikes = accelerations.filter { $0 >= startTripAccelerationThreshold }
        return spikes.count >= Int(sustainedAccelerationDuration)
    }

    func shouldPreemptivelyMonitor(samples: [MotionSample]) -> Bool {
        let spikes = samples.filter { $0.value >= startTripAccelerationThreshold }
        guard let first = spikes.first?.timestamp, let last = spikes.last?.timestamp else { return false }
        let duration = last.timeIntervalSince(first)
        return duration >= sustainedAccelerationDuration
    }

    // MARK: - Phase 2: GPS Speed Confirmation
    func shouldStartRecording(speeds: [CLLocationSpeed], accelerations: [Double]) -> Bool {
        let confirmedAccel = shouldPreemptivelyMonitor(accelerations: accelerations)
        let confirmedSpeed = speeds.allSatisfy { $0 >= startSpeedThreshold }
        return confirmedAccel && confirmedSpeed
    }

    func shouldStartRecording(speeds: [CLLocationSpeed], accelerationSamples: [MotionSample]) -> Bool {
        let confirmedAccel = shouldPreemptivelyMonitor(samples: accelerationSamples)
        let validSpeeds = speeds.filter { $0 >= startSpeedThreshold }
        let confirmedSpeed = validSpeeds.count >= 3
        return confirmedAccel && confirmedSpeed
    }

    // MARK: - Phase 3: Pausing
    func shouldPause(accelerations: [Double], currentLocation: CLLocation?) -> Bool {
        guard let currentLocation else { return false }
        let still = accelerations.allSatisfy { $0 < endTripAccelerationThreshold }
        let speedLow = true // speedBuffer unavailable in analyzer; handled externally
        let recentLocations: [CLLocation] = [] // also handled in monitor; for now we assume location doesn't change
        let withinRadius = recentLocations.allSatisfy {
            $0.distance(from: currentLocation) <= stationaryRadius
        }
        return still && speedLow && withinRadius
    }

    func shouldResume(accelerations: [Double], previousLocation: CLLocation?) -> Bool {
        guard let origin = previousLocation, let current = LocationService.shared.lastKnownLocation else { return false }
        let moved = current.distance(from: origin) > stationaryRadius
        let reactivated = accelerations.contains { $0 > startTripAccelerationThreshold }
        return moved && reactivated
    }
}
