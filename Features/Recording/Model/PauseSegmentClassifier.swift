import Foundation
import CoreLocation

/// Utility struct for classifying pause segments in trip data.
struct PauseSegmentClassifier {
    private static let headingThreshold: CLLocationDirection = 30.0
    
    /// Determines if a paused segment should be merged with the previous segment.
    /// Returns `true` if the pause likely represents stop-and-go traffic.
    ///
    /// - Parameters:
    ///   - segment: The segment representing a pause in movement.
    ///   - anchorHeading: The reference heading to compare the segment's path to.
    ///   - headingBuffer: The buffer of heading values during the pause.
    /// - Returns: `true` if the segment should be merged, `false` otherwise.
    static func shouldMerge(
        _ segment: TripSegment,
        anchorHeading: CLLocationDirection,
        headingBuffer: [CLLocationDirection]
    ) -> Bool {
        print("Raw Heading Buffer: \(headingBuffer)")
        
        if segment.duration < 30 {
            print("Determination: Merge segment — short pause duration (\(segment.duration) seconds)")
            return true
        } else if headingBuffer.count < 5 {
            print("Determination: Merge segment — insufficient heading data (\(headingBuffer.count) updates)")
            return true
        }
        
        let firstHeading = headingBuffer.first ?? anchorHeading
        let phoneOrientationOffset = (firstHeading - anchorHeading + 540).truncatingRemainder(dividingBy: 360) - 180
        print("Initial phone orientation offset from anchor heading: \(phoneOrientationOffset)°")
        
        let adjustedHeadings = headingBuffer.map { heading in
            (heading - phoneOrientationOffset + 360).truncatingRemainder(dividingBy: 360)
        }
        print("Offset Adjusted Headings: \(adjustedHeadings)")
        
        // ±90° offset check from anchor heading
        let within90Degrees = adjustedHeadings.allSatisfy { heading in
            let delta = (heading - anchorHeading + 540).truncatingRemainder(dividingBy: 360) - 180
            return abs(delta) <= 90
        }
        
        if within90Degrees {
            print("Determination: Merge segment — all headings within ±90° of anchor heading")
            return true
        }

        let normalizedHeadings = normalizeHeadings(adjustedHeadings)
        let scaledHeadings = scaleHeadingsToUnitVariance(normalizedHeadings)
        let maxVariance = scaledHeadings.max() ?? 0.0
        let avgVariance = scaledHeadings.reduce(0, +) / Double(scaledHeadings.count)
        
        print("Normalized Headings: \(normalizedHeadings)")
        print("Scaled Headings: \(scaledHeadings)")
        print("AVERAGE VAR: \(avgVariance)")
        print("MAX VAR: \(maxVariance)")
        
        if avgVariance > 0.45 || maxVariance > 0.7 {
            print("Determination: Discard segment")
            return false
        }
        
        print("Determination: Merge segment")
        return true
    }
    /// Normalizes an array of heading values to avoid wraparound discontinuities.
    /// For example, values near 0 and 360 degrees will be adjusted for consistent averaging.
    static func normalizeHeadings(_ headings: [CLLocationDirection]) -> [CLLocationDirection] {
        guard let reference = headings.first else { return headings }
        return headings.map { heading in
            let delta = heading - reference
            let adjusted = (delta + 540).truncatingRemainder(dividingBy: 360) - 180
            return reference + adjusted
        }
    }
    /// Converts an array of heading values into normalized variance values on a 0...1 scale.
    /// This helps quantify directional variability for heuristic classification.
    static func scaleHeadingsToUnitVariance(_ headings: [CLLocationDirection]) -> [Double] {
        guard headings.count >= 2 else { return [] }
        
        let normalized = normalizeHeadings(headings)
        let mean = normalized.reduce(0, +) / Double(normalized.count)
        let variances = normalized.map { abs($0 - mean) }
        
        guard let maxVariance = variances.max(), maxVariance != 0 else {
            return variances.map { _ in 0.0 }
        }
        
        return variances.map { $0 / maxVariance }
    }
    
    /// Computes the angular difference between each heading in the array and the anchor heading.
    /// Values are adjusted to the shortest angular path (-180 to +180).
    static func headingDeltas(from anchor: CLLocationDirection, to headings: [CLLocationDirection]) -> [CLLocationDirection] {
        return headings.map { heading in
            let delta = heading - anchor
            let adjustedDelta = (delta + 180).truncatingRemainder(dividingBy: 360) - 180
            return adjustedDelta
        }
    }
    
}
