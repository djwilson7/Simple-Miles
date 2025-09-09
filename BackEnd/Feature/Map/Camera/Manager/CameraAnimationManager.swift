import Foundation
import _MapKit_SwiftUI
import CoreLocation

/// Coordinates time-based interpolation between MapCamera states for smooth map transitions.
/// UI-facing manager that runs on the main actor and invokes onUpdate on the main run loop.
@MainActor
final class CameraAnimationManager {

    // MARK: - Published State
    // (No published state; consumers provide onUpdate closures.)

    // MARK: - Private
    private var cameraAnimationTimer: Timer?
    private var animationStartCamera: MapCamera?
    private var animationTargetCamera: MapCamera?
    private var cameraAnimationStartTime: Date?
    private var cameraAnimationDuration: TimeInterval = 0.8

    // Callbacks for timer tick
    private var animationOnUpdate: ((MapCamera) -> Void)?
    private var animationOnComplete: (() -> Void)?

    // Optional timing diagnostics/smoothing
    private var lastCameraUpdateAt: Date?
    private var expectedUpdateInterval: TimeInterval = 1.0

    // MARK: - Init
    init() {}

    // MARK: - Public API
    /// Animate from a start camera to an end camera, optionally tuned for review interactions.
    /// - Parameters:
    ///   - start: Starting camera state.
    ///   - end: Target camera state.
    ///   - isReviewing: If true, uses a slightly shorter default duration.
    ///   - onUpdate: Called on each frame with the interpolated camera.
    ///   - onComplete: Called once when the animation completes.
    func animate(
        from start: MapCamera,
        to end: MapCamera,
        isReviewing: Bool,
        onUpdate: @escaping (MapCamera) -> Void,
        onComplete: (() -> Void)? = nil
    ) {
        // If we are retargeting mid-flight, advance the start to the current eased position
        if let timer = cameraAnimationTimer,
           timer.isValid,
           let currentStart = animationStartCamera,
           let currentEnd = animationTargetCamera,
           let startTime = cameraAnimationStartTime
        {
            let elapsed = Date().timeIntervalSince(startTime)
            let tNorm = min(elapsed / cameraAnimationDuration, 1.0)
            let eased = Self.easeInOutCosine(tNorm)
            let interpolated = Self.interpolate(from: currentStart, to: currentEnd, t: eased)
            animationStartCamera = interpolated
        } else {
            animationStartCamera = start
        }

        // Optional smoothing/diagnostics (kept for future use)
        let now = Date()
        if let last = lastCameraUpdateAt {
            let dt = now.timeIntervalSince(last)
            expectedUpdateInterval = (0.8 * expectedUpdateInterval) + (0.2 * dt)
        }
        lastCameraUpdateAt = now

        cameraAnimationDuration = isReviewing ? 0.8 : 0.95

        animationTargetCamera = end
        cameraAnimationStartTime = Date()

        // Store callbacks for use in the timer tick
        animationOnUpdate = onUpdate
        animationOnComplete = onComplete

        // Invalidate any existing timer
        cameraAnimationTimer?.invalidate()
        cameraAnimationTimer = nil

        // Create selector-based timer to avoid @Sendable closure capturing MainActor-isolated state
        let timer = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(handleTimerTick(_:)), userInfo: nil, repeats: true)
        cameraAnimationTimer = timer
        RunLoop.main.add(timer, forMode: .common)
        timer.tolerance = 0
    }

    // MARK: - Timer Tick
    @objc
    private func handleTimerTick(_ timer: Timer) {
        guard
            let start = animationStartCamera,
            let target = animationTargetCamera,
            let startTime = cameraAnimationStartTime
        else {
            timer.invalidate()
            cameraAnimationTimer = nil
            animationOnUpdate = nil
            animationOnComplete = nil
            return
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let tNorm = min(elapsed / cameraAnimationDuration, 1.0)
        let eased = Self.easeInOutCosine(tNorm)

        let interpolated = Self.interpolate(from: start, to: target, t: eased)
        animationOnUpdate?(interpolated)

        if tNorm >= 1.0 - .ulpOfOne {
            timer.invalidate()
            cameraAnimationTimer = nil
            let completion = animationOnComplete
            // Clear callbacks to break potential retain cycles
            animationOnUpdate = nil
            animationOnComplete = nil
            completion?()
        }
    }

    // MARK: - Private Helpers
    private static func easeInOutCosine(_ t: Double) -> Double {
        // Smooth, symmetric ease-in-out using cosine
        0.5 * (1 - cos(.pi * max(0, min(1, t))))
    }

    private static func shortestHeadingDelta(from start: CLLocationDirection, to end: CLLocationDirection) -> CLLocationDirection {
        // Compute shortest signed delta in [-180, 180)
        ((end - start + 540).truncatingRemainder(dividingBy: 360)) - 180
    }

    private static func normalizeHeading(_ h: CLLocationDirection) -> CLLocationDirection {
        var value = h.truncatingRemainder(dividingBy: 360)
        if value < 0 { value += 360 }
        return value
    }

    private static func interpolate(from a: MapCamera, to b: MapCamera, t: Double) -> MapCamera {
        var out = b

        // Position
        out.centerCoordinate.latitude =
            a.centerCoordinate.latitude + (b.centerCoordinate.latitude - a.centerCoordinate.latitude) * t
        out.centerCoordinate.longitude =
            a.centerCoordinate.longitude + (b.centerCoordinate.longitude - a.centerCoordinate.longitude) * t

        // Distance (zoom)
        out.distance = a.distance + (b.distance - a.distance) * t

        // Heading (shortest path)
        let delta = shortestHeadingDelta(from: a.heading, to: b.heading)
        out.heading = normalizeHeading(a.heading + delta * t)

        return out
    }

    // MARK: - Deinit
    deinit {
        cameraAnimationTimer?.invalidate()
        cameraAnimationTimer = nil
    }
}
