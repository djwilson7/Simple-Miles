import Foundation
import CoreLocation

/// Generates spline-smoothed trace segments that connect ground-truth GPS coordinates
/// to the physics-driven simulated puck. This ensures the visual path is smooth and
/// doesn't show "physics squiggles" from the puck's drift correction.
@MainActor
final class LocationAnimationManager {

    // MARK: - Init
    init() {}

    func reset() {
        // No-op for now as we are stateless spline generators
    }

    /// Generates a smooth spline tail connecting historical ground truth to the current puck.
    /// - Parameters:
    ///   - groundTruth: The last few recorded GPS coordinates (ordered oldest to newest).
    ///   - puck: The current simulated puck location from the physics engine.
    /// - Returns: A polyline of coordinates forming a smooth curve.
    func generateSplineTail(
        groundTruth: [CLLocationCoordinate2D],
        puck: CLLocationCoordinate2D
    ) -> [CLLocationCoordinate2D] {
        // We need at least 3 points to create a grounded spline: GT(n-2), GT(n-1), Puck.
        // If we have fewer, we fall back to simpler lines.
        guard groundTruth.count >= 2 else {
            if let latest = groundTruth.last {
                return [latest, puck]
            } else {
                return [puck]
            }
        }

        // To match MapViewModel's flickering fix, we start the spline at the second-to-last ground truth point.
        // P1 = GT(n-2) : The stable anchor where the static line ends.
        // P2 = GT(n-1) : The latest ground truth we are passing through.
        // P3 = Puck    : The target destination.
        
        let p1 = groundTruth[groundTruth.count - 2]
        let p2 = groundTruth.last!
        let p3 = puck
        
        // Catmull-Rom needs 4 points. We'll use p0 as a phantom point behind p1 to maintain curvature.
        let p0 = groundTruth.count >= 3 ? groundTruth[groundTruth.count - 3] : p1
        
        // Generate the spline from P1 to P2, then from P2 to P3.
        let firstSection = interpolateSection(p0: p0, p1: p1, p2: p2, p3: p3, segments: 10)
        
        // For the final section (P2 to P3), we need a P4 control point. 
        // We'll project a small distance ahead to ensure the curve enters the puck naturally.
        let finalBearing = p2.bearing(to: p3)
        let p4 = p3.coordinate(at: 1.0, bearing: finalBearing) // Tighter look-ahead
        
        // Drop the first point of the second section to avoid duplicating P2
        let secondSection = Array(interpolateSection(p0: p1, p1: p2, p2: p3, p3: p4, segments: 15).dropFirst())

        return firstSection + secondSection
    }

    // MARK: - Private Helpers
    private func interpolateSection(
        p0: CLLocationCoordinate2D,
        p1: CLLocationCoordinate2D,
        p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D,
        segments: Int
    ) -> [CLLocationCoordinate2D] {
        var path: [CLLocationCoordinate2D] = []
        for i in 0...segments {
            let t = Double(i) / Double(segments)
            path.append(catmullRom(p0: p0, p1: p1, p2: p2, p3: p3, t: t))
        }
        return path
    }

    private func catmullRom(
        p0: CLLocationCoordinate2D,
        p1: CLLocationCoordinate2D,
        p2: CLLocationCoordinate2D,
        p3: CLLocationCoordinate2D,
        t: Double
    ) -> CLLocationCoordinate2D {
        let t2 = t * t
        let t3 = t2 * t

        let f1 = -0.5 * t3 + t2 - 0.5 * t
        let f2 = 1.5 * t3 - 2.5 * t2 + 1.0
        let f3 = -1.5 * t3 + 2.0 * t2 + 0.5 * t
        let f4 = 0.5 * t3 - 0.5 * t2

        let lat = p0.latitude * f1 + p1.latitude * f2 + p2.latitude * f3 + p3.latitude * f4
        let lon = p0.longitude * f1 + p1.longitude * f2 + p2.longitude * f3 + p3.longitude * f4

        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
