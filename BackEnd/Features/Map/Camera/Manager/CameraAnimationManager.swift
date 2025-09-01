import Foundation
import _MapKit_SwiftUI
import CoreLocation

final class CameraAnimationManager {
    private var cameraAnimationTimer: Timer?
    private var animationStartCamera: MapCamera?
    private var animationTargetCamera: MapCamera?
    private var cameraAnimationStartTime: Date?
    private var cameraAnimationDuration: TimeInterval = 0.8
    
    private var lastCameraUpdateAt: Date?
    private var expectedUpdateInterval: TimeInterval = 1.0
    
    func animate(
        from start: MapCamera,
        to end: MapCamera,
        isReviewing: Bool,
        onUpdate: @escaping (MapCamera) -> Void,
        onComplete: (() -> Void)? = nil
    ) {

        if let timer = cameraAnimationTimer, timer.isValid,
           let currentStart = animationStartCamera,
           let currentEnd = animationTargetCamera,
           let startTime = cameraAnimationStartTime {
            
            let elapsed = Date().timeIntervalSince(startTime)
            let tNorm = min(elapsed / cameraAnimationDuration, 1.0)
            let eased = 0.5 * (1 - cos(.pi * tNorm))
            
            var interpolatedCamera = currentEnd
            interpolatedCamera.centerCoordinate.latitude =
                currentStart.centerCoordinate.latitude + (currentEnd.centerCoordinate.latitude - currentStart.centerCoordinate.latitude) * eased
            interpolatedCamera.centerCoordinate.longitude =
                currentStart.centerCoordinate.longitude + (currentEnd.centerCoordinate.longitude - currentStart.centerCoordinate.longitude) * eased
            interpolatedCamera.distance =
                currentStart.distance + (currentEnd.distance - currentStart.distance) * eased

            let startHeading = currentStart.heading
            let endHeading = currentEnd.heading
            let delta = ((endHeading - startHeading + 540).truncatingRemainder(dividingBy: 360)) - 180
            interpolatedCamera.heading = (startHeading + delta * eased).truncatingRemainder(dividingBy: 360)
            if interpolatedCamera.heading < 0 {
                interpolatedCamera.heading += 360
            }
            
            print("center: \(interpolatedCamera.centerCoordinate), heading: \(interpolatedCamera.heading)")
            animationStartCamera = interpolatedCamera
        } else {
            animationStartCamera = start
        }
        
        let now = Date()
        if let last = lastCameraUpdateAt {
            let dt = now.timeIntervalSince(last)
            expectedUpdateInterval = (0.8 * expectedUpdateInterval) + (0.2 * dt)
        }
        lastCameraUpdateAt = now
        
        if isReviewing {
            cameraAnimationDuration = 0.8
        } else {
            cameraAnimationDuration = 0.95
        }
        
        animationTargetCamera = end
        cameraAnimationStartTime = Date()
        
        cameraAnimationTimer?.invalidate()
        
        cameraAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard
                let self,
                let start = self.animationStartCamera,
                let end = self.animationTargetCamera,
                let startTime = self.cameraAnimationStartTime
            else {
                timer.invalidate()
                return
            }
            
            let elapsed = Date().timeIntervalSince(startTime)
            let tNorm = min(elapsed / self.cameraAnimationDuration, 1.0)
            
            let eased = 0.5 * (1 - cos(.pi * tNorm))
            
            var interpolatedCamera = end
            interpolatedCamera.centerCoordinate.latitude =
            start.centerCoordinate.latitude + (end.centerCoordinate.latitude - start.centerCoordinate.latitude) * eased
            interpolatedCamera.centerCoordinate.longitude =
            start.centerCoordinate.longitude + (end.centerCoordinate.longitude - start.centerCoordinate.longitude) * eased
            interpolatedCamera.distance =
            start.distance + (end.distance - start.distance) * eased
            
            let startHeading = start.heading
            let endHeading = end.heading
            let delta = ((endHeading - startHeading + 540).truncatingRemainder(dividingBy: 360)) - 180
            interpolatedCamera.heading = (startHeading + delta * eased).truncatingRemainder(dividingBy: 360)
            if interpolatedCamera.heading < 0 {
                interpolatedCamera.heading += 360
            }
            
            
            onUpdate(interpolatedCamera)
            
            if tNorm >= 1.0 - .ulpOfOne {
                timer.invalidate()
                self.cameraAnimationTimer = nil
                onComplete?()
            }
        }
        
        RunLoop.main.add(cameraAnimationTimer!, forMode: .common)
        cameraAnimationTimer?.tolerance = 0
    }
}

