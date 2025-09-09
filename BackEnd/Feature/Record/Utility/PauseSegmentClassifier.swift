import Foundation
import CoreLocation

struct PauseSegmentClassifier {
    private static let headingThreshold: CLLocationDirection = 30.0
    
    static func shouldMerge(
        _ segment: TripSegment,
        anchorHeading: CLLocationDirection,
        headingBuffer: [CLLocationDirection]
    ) -> Bool {
        Log("Raw Heading Buffer: \(headingBuffer)")
        
        if segment.duration < 30 {
            Log("Short Pause Duration: \(segment.duration)s")
            return true
        } else if headingBuffer.count < 5 {
            Log("Insufficient Heading Data: \(headingBuffer.count) updates")
            return true
        }
        
        let firstHeading = headingBuffer.first ?? anchorHeading
        let phoneOrientationOffset = (firstHeading - anchorHeading + 540).truncatingRemainder(dividingBy: 360) - 180
        Log("Inital Phone Orientation Offset: \(phoneOrientationOffset)")
        
        let adjustedHeadings = headingBuffer.map { heading in
            (heading - phoneOrientationOffset + 360).truncatingRemainder(dividingBy: 360)
        }
        Log("Offset Adjusted Heading: \(adjustedHeadings)")
        
        let within90Degrees = adjustedHeadings.allSatisfy { heading in
            let delta = (heading - anchorHeading + 540).truncatingRemainder(dividingBy: 360) - 180
            return abs(delta) <= 90
        }
        
        if within90Degrees {
            Log("Merge Segment: All Headings within ±90° of anchor heading")
            return true
        }

        let normalizedHeadings = normalizeHeadings(adjustedHeadings)
        let scaledHeadings = scaleHeadingsToUnitVariance(normalizedHeadings)
        let maxVariance = scaledHeadings.max() ?? 0.0
        let avgVariance = scaledHeadings.reduce(0, +) / Double(scaledHeadings.count)
        
        if avgVariance > 0.45 || maxVariance > 0.7 {
            Log("Discard Segment: AVG Var \(avgVariance) MAX Var \(maxVariance)")
            return false
        }
        Log("Merge Segment: AVG Var \(avgVariance) MAX Var \(maxVariance)")
        return true
    }
    
    static func normalizeHeadings(_ headings: [CLLocationDirection]) -> [CLLocationDirection] {
        guard let reference = headings.first else { return headings }
        return headings.map { heading in
            let delta = heading - reference
            let adjusted = (delta + 540).truncatingRemainder(dividingBy: 360) - 180
            return reference + adjusted
        }
    }
    
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
    
    static func headingDeltas(from anchor: CLLocationDirection, to headings: [CLLocationDirection]) -> [CLLocationDirection] {
        return headings.map { heading in
            let delta = heading - anchor
            let adjustedDelta = (delta + 180).truncatingRemainder(dividingBy: 360) - 180
            return adjustedDelta
        }
    }
    
}
