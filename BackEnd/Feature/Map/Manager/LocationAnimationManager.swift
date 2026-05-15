import Foundation
import CoreLocation

/// Coordinates time-based interpolation between LocationPoint samples,
/// producing smooth intermediate positions and an optional tail segment to an anchor.
/// UI-facing; runs on the main actor and invokes onUpdate on the main run loop.
@MainActor
final class LocationAnimationManager {

    // MARK: - Published/Public State (Outputs)
    var isAnimating: Bool { animationTimer?.isValid ?? false }

    // MARK: - Private State
    var animationTimer: Timer?
    var animationStartLocation: LocationPoint?
    var animationTargetLocation: LocationPoint?
    var animationStartTime: Date?
    var animationDuration: TimeInterval = 1.0

    var lastLocationUpdateAt: Date?
    var expectedUpdateInterval: TimeInterval = 1.0
    var smoothedSpeedMPS: Double?

    var currentLiveAnchor: CLLocationCoordinate2D?
    var currentStaticLast: CLLocationCoordinate2D?
    var lastValidAnchor: CLLocationCoordinate2D?

    // Stored callback for selector-based timer tick
    var animationOnUpdate: ((_ interpolated: LocationPoint, _ tail: [CLLocationCoordinate2D]) -> Void)?

    // MARK: - Init
    init() {}

    // MARK: - Public API (Intents)
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
        animationOnUpdate = nil
    }

    func updateAnchors(live: LocationPoint?, staticLast: LocationPoint?) {
        currentLiveAnchor = live?.coordinate
        currentStaticLast = staticLast?.coordinate
    }

    /// Animate from an optional start to an end point. If not traveling, immediately publishes end + tail.
    /// - Parameters:
    ///   - start: Optional starting sample; falls back to end if nil.
    ///   - end: Target sample.
    ///   - travelStateIsTraveling: Whether user is currently in traveling state.
    ///   - onUpdate: Called on each frame with interpolated point and optional tail polyline (anchor -> point).
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

        // Smooth speed to stabilize duration estimates
        let raw = max(end.speed, 0)
        if smoothedSpeedMPS == nil { smoothedSpeedMPS = raw }
        smoothedSpeedMPS = (0.75 * (smoothedSpeedMPS ?? raw)) + (0.25 * raw)
        smoothedSpeedMPS = min(max(smoothedSpeedMPS ?? raw, 1.0), 60.0)

        let currentStartFallback = start ?? end
        if currentStartFallback.distance(to: end) < 0.5 {
            // Too close to animate; publish directly with tail
            let anchor = currentLiveAnchor ?? currentStaticLast ?? lastValidAnchor
            let tail: [CLLocationCoordinate2D] = anchor.map { [$0, end.coordinate] } ?? []
            if let a = anchor { lastValidAnchor = a }
            onUpdate(end, tail)
            return
        }

        // If retargeting mid-flight, advance start to current interpolated position
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

        // Reset timer and set new targets
        animationTimer?.invalidate()
        animationStartLocation = currentPosition
        animationTargetLocation = end

        // Timing diagnostics to adapt cadence
        let now = Date()
        if let last = lastLocationUpdateAt {
            let dt = now.timeIntervalSince(last)
            expectedUpdateInterval = (0.8 * expectedUpdateInterval) + (0.2 * dt)
        }
        lastLocationUpdateAt = now
        animationStartTime = now

        // Determine duration using distance and smoothed speed, constrained by expected cadence
        let distance = currentPosition.distance(to: end)
        let mps = smoothedSpeedMPS ?? 12.0
        var duration = distance / mps

        let cadenceMin = max(0.18, 0.85 * expectedUpdateInterval)
        let cadenceMax = max(0.50, 1.15 * expectedUpdateInterval)
        duration = min(max(duration, cadenceMin), cadenceMax)

        let hardMin: TimeInterval = 0.18
        let hardMax: TimeInterval = 1.8
        animationDuration = min(max(duration, hardMin), hardMax)

        // Store callback and start loop
        startAnimationLoop(onUpdate: onUpdate)
    }

    // MARK: - Private Helpers
    private func startAnimationLoop(
        onUpdate: @escaping (_ interpolated: LocationPoint, _ tail: [CLLocationCoordinate2D]) -> Void
    ) {
        animationTimer?.invalidate()
        animationOnUpdate = onUpdate

        let timer = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(handleTimerTick(_:)), userInfo: nil, repeats: true)
        animationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        timer.tolerance = 0
    }

    @objc
    func handleTimerTick(_ timer: Timer) {
        guard
            let start = animationStartLocation,
            let end = animationTargetLocation,
            let startTime = animationStartTime
        else {
            timer.invalidate()
            animationTimer = nil
            animationOnUpdate = nil
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let t = min(elapsed / animationDuration, 1.0)

        let lat = start.coordinate.latitude + (end.coordinate.latitude - start.coordinate.latitude) * t
        let lon = start.coordinate.longitude + (end.coordinate.longitude - start.coordinate.longitude) * t
        let syntheticCL = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon),
            altitude: 0,
            horizontalAccuracy: Double.greatestFiniteMagnitude,
            verticalAccuracy: Double.greatestFiniteMagnitude,
            course: start.course,
            speed: smoothedSpeedMPS ?? start.speed,
            timestamp: Date()
        )
        let interpolatedLocation = LocationPoint(syntheticCL)
        let anchor = currentLiveAnchor ?? currentStaticLast ?? lastValidAnchor
        let tail: [CLLocationCoordinate2D] = anchor.map { [$0, interpolatedLocation.coordinate] } ?? []
        if let a = anchor { lastValidAnchor = a }

        animationOnUpdate?(interpolatedLocation, tail)

        if t >= 1.0 - .ulpOfOne {
            timer.invalidate()
            animationTimer = nil
            animationOnUpdate = nil
        }
    }

    // MARK: - Deinit
    deinit {
        animationTimer?.invalidate()
        animationTimer = nil
        animationOnUpdate = nil
    }
}
