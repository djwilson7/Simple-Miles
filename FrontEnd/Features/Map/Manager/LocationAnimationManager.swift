import Foundation
import CoreLocation

final class LocationAnimationManager {

    private var animationTimer: Timer?
    private var animationStartLocation: LocationPoint?
    private var animationTargetLocation: LocationPoint?
    private var animationStartTime: Date?
    private var animationDuration: TimeInterval = 1.0

    private var lastLocationUpdateAt: Date?
    private var expectedUpdateInterval: TimeInterval = 1.0
    private var smoothedSpeedMPS: Double?

    private var currentLiveAnchor: CLLocationCoordinate2D?
    private var currentStaticLast: CLLocationCoordinate2D?
    private var lastValidAnchor: CLLocationCoordinate2D?

    var isAnimating: Bool { animationTimer?.isValid ?? false }

    func reset() {
        animationTimer?.invalidate()
        animationTimer = nil
        animationStartLocation = nil
        animationTargetLocation = nil
        animationStartTime = nil
        lastLocationUpdateAt = nil
        expectedUpdateInterval = 1.0
        smoothedSpeedMPS = nil
        lastValidAnchor = nil
    }

    func updateAnchors(live: LocationPoint?, staticLast: LocationPoint?) {
        currentLiveAnchor = live?.coordinate
        currentStaticLast = staticLast?.coordinate
    }

    func animate(
        from start: LocationPoint?,
        to end: LocationPoint,
        travelStateIsTraveling: Bool,
        onUpdate: @escaping (_ interpolated: LocationPoint, _ tail: [CLLocationCoordinate2D]) -> Void
    ) {
        guard travelStateIsTraveling else {
            let anchor = currentLiveAnchor ?? currentStaticLast
            let tail: [CLLocationCoordinate2D] = anchor.map { [$0, end.coordinate] } ?? []
            if let a = anchor { lastValidAnchor = a }
            onUpdate(end, tail)
            return
        }

        let raw = max(end.speed, 0)
        if smoothedSpeedMPS == nil { smoothedSpeedMPS = raw }
        smoothedSpeedMPS = (0.75 * (smoothedSpeedMPS ?? raw)) + (0.25 * raw)
        smoothedSpeedMPS = min(max(smoothedSpeedMPS ?? raw, 1.0), 60.0)

        let currentStartFallback = start ?? end
        if currentStartFallback.distance(to: end) < 0.5 {
            let anchor = currentLiveAnchor ?? currentStaticLast ?? lastValidAnchor
            let tail: [CLLocationCoordinate2D] = anchor.map { [$0, end.coordinate] } ?? []
            if let a = anchor { lastValidAnchor = a }
            onUpdate(end, tail)
            return
        }

        let currentPosition: LocationPoint = {
            if let timer = animationTimer, timer.isValid,
               let animStart = animationStartLocation,
               let animEnd = animationTargetLocation,
               let animStartTime = animationStartTime {
                let elapsed = Date().timeIntervalSince(animStartTime)
                let clampedT = min(elapsed / animationDuration, 1.0)
                let lat = animStart.coordinate.latitude + (animEnd.coordinate.latitude - animStart.coordinate.latitude) * clampedT
                let lon = animStart.coordinate.longitude + (animEnd.coordinate.longitude - animStart.coordinate.longitude) * clampedT
                let syntheticCL = CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                    altitude: 0,
                    horizontalAccuracy: Double.greatestFiniteMagnitude,
                    verticalAccuracy: Double.greatestFiniteMagnitude,
                    course: animStart.course,
                    speed: smoothedSpeedMPS ?? animStart.speed,
                    timestamp: Date()
                )
                return LocationPoint(syntheticCL)
            } else {
                return start ?? end
            }
        }()

        animationTimer?.invalidate()

        animationStartLocation = currentPosition
        animationTargetLocation = end

        let now = Date()
        if let last = lastLocationUpdateAt {
            let dt = now.timeIntervalSince(last)
            expectedUpdateInterval = (0.8 * expectedUpdateInterval) + (0.2 * dt)
        }
        lastLocationUpdateAt = now
        animationStartTime = now

        let distance = currentPosition.distance(to: end)
        let mps = smoothedSpeedMPS ?? 12.0
        var duration = distance / mps

        let cadenceMin = max(0.18, 0.85 * expectedUpdateInterval)
        let cadenceMax = max(0.50, 1.15 * expectedUpdateInterval)
        duration = min(max(duration, cadenceMin), cadenceMax)

        let hardMin: TimeInterval = 0.18
        let hardMax: TimeInterval = 1.8
        animationDuration = min(max(duration, hardMin), hardMax)

        startAnimationLoop(onUpdate: onUpdate)
    }

    private func startAnimationLoop(
        onUpdate: @escaping (_ interpolated: LocationPoint, _ tail: [CLLocationCoordinate2D]) -> Void
    ) {
        animationTimer?.invalidate()

        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard
                let self,
                let start = self.animationStartLocation,
                let end = self.animationTargetLocation,
                let startTime = self.animationStartTime
            else { return }

            let elapsed = Date().timeIntervalSince(startTime)
            let t = min(elapsed / self.animationDuration, 1.0)

            let lat = start.coordinate.latitude + (end.coordinate.latitude - start.coordinate.latitude) * t
            let lon = start.coordinate.longitude + (end.coordinate.longitude - start.coordinate.longitude) * t
            let syntheticCL = CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                altitude: 0,
                horizontalAccuracy: Double.greatestFiniteMagnitude,
                verticalAccuracy: Double.greatestFiniteMagnitude,
                course: start.course,
                speed: self.smoothedSpeedMPS ?? start.speed,
                timestamp: Date()
            )
            let interpolatedLocation = LocationPoint(syntheticCL)
            let anchor = self.currentLiveAnchor ?? self.currentStaticLast ?? self.lastValidAnchor
            let tail: [CLLocationCoordinate2D] = anchor.map { [$0, interpolatedLocation.coordinate] } ?? []
            if let a = anchor { self.lastValidAnchor = a }

            onUpdate(interpolatedLocation, tail)

            if t >= 1.0 {
                timer.invalidate()
                self.animationTimer = nil
            }
        }
        RunLoop.main.add(animationTimer!, forMode: .common)
    }
}
