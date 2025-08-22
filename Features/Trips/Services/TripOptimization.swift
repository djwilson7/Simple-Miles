//
//  TripOptimization.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/16/25.
//

import Foundation
import MapKit

// MARK: - TripOptimizer Class

public class TripOptimizer {
    // Simple anchor policy by index count:
    // - 2 points: start, end
    // - 3..9 points: start, middle, end (middle = points[n/2])
    // - 10..49 points: start, two inner anchors, end (at 1/3 and 2/3 positions)
    // - 50+ points: start, four inner anchors at quintiles, end
    private static func makeSimpleAnchors(from points: [LocationPoint]) -> [LocationPoint] {
        guard points.count >= 2 else { return points }
        let n = points.count
        
        if n == 2 {
            return [points.first!, points.last!]
        }
        
        if n < 10 {
            // One middle at index n/2 (integer division)
            let mid = n / 2
            return [points.first!, points[mid], points.last!]
        }
        
        if n < 50 {
            // Two inner anchors at indices 1/3 and 2/3 (rounded), ensure distinct and not endpoints
            let i1 = max(1, Int(round(Double(n - 1) * 1.0 / 3.0)))
            let i2 = min(n-2, Int(round(Double(n - 1) * 2.0 / 3.0)))
            var anchors: [LocationPoint] = [points.first!]
            if i1 != 0 && i1 != n-1 {
                anchors.append(points[i1])
            }
            if i2 != 0 && i2 != n-1 && i2 > i1 {
                anchors.append(points[i2])
            }
            anchors.append(points.last!)
            return anchors
        }
        
        // 50+ points: four inner anchors at quintiles (1/5, 2/5, 3/5, 4/5)
        var indices: [Int] = []
        for q in 1...4 {
            let idx = Int(round(Double(n - 1) * Double(q) / 5.0))
            let clamped = min(max(1, idx), n-2)
            indices.append(clamped)
        }
        
        // Deduplicate indices while preserving order
        var seen = Set<Int>()
        let deduped = indices.filter { seen.insert($0).inserted }
        var anchors: [LocationPoint] = [points.first!]
        
        for i in deduped {
            anchors.append(points[i])
        }
        
        anchors.append(points.last!)
        return anchors
    }

    /// Returns true if the tail of the segment looks like a stop (slow/idle).
    private static func isStopAtTail(_ pts: [LocationPoint], window: Int = 6, speedThresh: CLLocationSpeed = 1.0) -> Bool {
        guard !pts.isEmpty else { return false }
        let k = min(window, pts.count)
        let tail = pts.suffix(k)
        let avg = tail.map { max(0, $0.speed) }.reduce(0, +) / Double(k)
        return avg < speedThresh
    }

    /// Tail‑biased anchors to pin routing near the end of a leg on stacked roads.
    /// Always includes start/end. Walks backward from end by `tailStep` indices, up to `maxTail` anchors.
    /// Optionally adds one middle anchor if long enough. Caps total anchors to `maxTotal`.
    private static func makeTailBiasedAnchors(
        from points: [LocationPoint],
        tailStep: Int = 5,
        maxTail: Int = 3,
        includeMiddle: Bool = true,
        maxTotal: Int = 8
    ) -> [LocationPoint] {
        let n = points.count
        guard n >= 2 else { return points }
        if n == 2 { return [points.first!, points.last!] }

        var idxs: [Int] = [0, n - 1]

        // Tail anchors: end-5, end-10, end-15 ...
        if n > 3 && maxTail > 0 && tailStep > 0 {
            var added = 0
            var i = (n - 1) - tailStep
            while i > 0 && added < maxTail {
                idxs.append(i)
                added += 1
                i -= tailStep
            }
        }

        // Optional middle if we still have room and segment is reasonably long
        if includeMiddle && idxs.count < maxTotal && n >= 6 {
            idxs.append(n / 2)
        }

        // Dedupe, sort, and enforce cap while keeping start/end
        var set = Set<Int>()
        var unique = idxs.filter { set.insert($0).inserted }.sorted()
        // Ensure we keep room for the end index
        if unique.count > maxTotal {
            // Keep start, distribute the rest but leave space for end
            let keep = maxTotal - 1
            unique = Array(unique.prefix(keep))
            if unique.last != n - 1 { unique.append(n - 1) }
        } else if unique.last != n - 1 {
            unique.append(n - 1)
        }

        return unique.map { points[$0] }
    }
    
    

    // MARK: - Public Static Method: optimizeTrip
    /// Optimizes the given trip segment by splitting it into sub-segments based on bearing changes,
    /// then fetches optimized routes for each sub-segment using MKDirections, and stitches them into a single optimized path.
    /// - Parameters:
    ///   - segment: The TripSegment containing the pathCoordinates to optimize.
    ///   - bearingThreshold: The bearing change threshold (in degrees) to trigger a segment split. Defaults to 30 degrees.
    ///   - completion: A completion handler returning a Result containing the optimized array of CLLocationCoordinate2D or an Error.
    public static func optimizeTrip(
        segment: TripSegment,
        bearingThreshold: Double = 30,
        completion: @escaping (Result<[LocationPoint], Error>) -> Void
    ) {
        // Run off the main thread
        DispatchQueue.global(qos: .userInitiated).async {
            
            let coordinates = segment.pathCoordinates
            print("[1] Raw count:", coordinates.count)

            guard coordinates.count >= 2 else {
                completion(.success(coordinates))
                return
            }

            // Split the path into sub-segments by bearing threshold and speed intelligence
            let subSegments = segmentTripByBearing(
                coordinates: coordinates,
                bearingThreshold: bearingThreshold
            )
            let segCounts = subSegments.map { $0.count }
            print("[2] Segment counts:", segCounts)
            
            var optimizedCoordinates: [LocationPoint] = []
            let directionsSemaphore = DispatchSemaphore(value: 0)
            var lastError: Error? = nil
            
            for (outerIndex, subSegment) in subSegments.enumerated() {
                // ---- Sub-segment \(outerIndex) (\(subSegment.count) pts) ---- (removed for brevity)
                guard subSegment.count >= 2 else {
                    // Not enough points to request directions, just append the points
                    optimizedCoordinates.append(contentsOf: subSegment)
                    continue
                }

                let anchors: [LocationPoint]
                if isStopAtTail(subSegment) {
                    anchors = makeTailBiasedAnchors(from: subSegment, tailStep: 5, maxTail: 3, includeMiddle: true, maxTotal: 8)
                } else {
                    anchors = makeSimpleAnchors(from: subSegment)
                }

                var mkdLegsForSubseg = 0
                var mkdVertsForSubseg = 0

                for i in 0..<(anchors.count - 1) {
                    let legStart = anchors[i]
                    let legEnd = anchors[i+1]
                    let request = MKDirections.Request()
                    request.source = MKMapItem(location: CLLocation(latitude: legStart.coordinate.latitude, longitude: legStart.coordinate.longitude), address: nil)
                    request.destination = MKMapItem(location: CLLocation(latitude: legEnd.coordinate.latitude, longitude: legEnd.coordinate.longitude), address: nil)
                    request.transportType = .automobile
                    request.requestsAlternateRoutes = false

                    let directions = MKDirections(request: request)
                    directions.calculate { response, error in
                        if let route = response?.routes.first {
                            let verts = route.polyline.coordinates
                            mkdLegsForSubseg += 1
                            mkdVertsForSubseg += verts.count
                            let routePoints = verts.map { LocationPoint(CLLocation(latitude: $0.latitude, longitude: $0.longitude)) }
                            optimizedCoordinates.append(contentsOf: routePoints)
                        } else {
                            optimizedCoordinates.append(contentsOf: Array(subSegment))
                            if let error = error {
                                lastError = error
                            }
                        }
                        directionsSemaphore.signal()
                    }
                    directionsSemaphore.wait()
                }
                print("[3] MKD legs (subseg \(outerIndex)):", mkdLegsForSubseg, ", verts:", mkdVertsForSubseg)
            }
            
            print("[4] Pre-dup count:", optimizedCoordinates.count)
            let cleanedCoordinates = removeDuplicateConsecutiveCoordinates(from: optimizedCoordinates)
            print("[5] Post-dup count:", cleanedCoordinates.count)

            let rawTailWindow: [CLLocationCoordinate2D] = Array(coordinates.suffix(10)).map { $0.coordinate }
            if let tailFirst = rawTailWindow.first, let tailLast = rawTailWindow.last {
                let tailSpanMeters = tailFirst.distance(to: tailLast)
                print("[6a] Raw tail span (first→last):", Int(tailSpanMeters), "m (pts:", rawTailWindow.count, ")")
            } else {
                print("[6a] Raw tail span: N/A (pts:", rawTailWindow.count, ")")
            }
            let stitchedCoords = cleanedCoordinates.map { $0.coordinate }
            print("[6] Pre-clip total:", stitchedCoords.count)
            let finalClippedCoords = clipFinalPath(
                stitchedCoords,
                rawTail: rawTailWindow
            )
            print("[7] Post-clip total:", finalClippedCoords.count)

            print("[8] Pre-enrich total:", finalClippedCoords.count)
            let enrichedClipped: [LocationPoint] = enrichClippedMonotone(mkd: finalClippedCoords, raw: coordinates)
            print("[9] Post-enrich total:", enrichedClipped.count)

            DispatchQueue.main.async {
                if let error = lastError, enrichedClipped.isEmpty {
                    completion(.failure(error))
                } else {
                    completion(.success(enrichedClipped))
                }
            }
        }
    }
    
    // MARK: - Helper Method: Bearing Calculation
    /// Computes the initial bearing (forward azimuth) from one coordinate to another in degrees.
    /// - Parameters:
    ///   - from: Start coordinate.
    ///   - to: End coordinate.
    /// - Returns: Bearing in degrees, 0-360.
    public static func bearing(from: LocationPoint, to: LocationPoint) -> Double {
        let lat1 = from.coordinate.latitude.degreesToRadians
        let lon1 = from.coordinate.longitude.degreesToRadians
        let lat2 = to.coordinate.latitude.degreesToRadians
        let lon2 = to.coordinate.longitude.degreesToRadians
        
        let deltaLon = lon2 - lon1
        
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1)*sin(lat2) - sin(lat1)*cos(lat2)*cos(deltaLon)
        let radiansBearing = atan2(y, x)
        
        var degreesBearing = radiansBearing.radiansToDegrees
        degreesBearing = (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
        
        return degreesBearing
    }
    
    // MARK: - Helper Method: Segment Trip by Bearing with Speed Intelligence
    /// Splits a list of coordinates into sub-segments where significant bearing change exceeds the threshold.
    /// This method refines the splitting logic so that only strong, rapid bearing changes (not gradual or accumulated slight shifts)
    /// cause a split. It uses a minimum distance threshold to detect strong turns and speed intelligence to avoid splitting during high speed.
    /// - Parameters:
    ///   - coordinates: The full path coordinates.
    ///   - bearingThreshold: Bearing change threshold (degrees) to start a new segment.
    /// - Returns: Array of coordinate arrays, each representing a sub-segment.
    public static func segmentTripByBearing(
        coordinates: [LocationPoint],
        bearingThreshold: Double
    ) -> [[LocationPoint]] {
        guard coordinates.count >= 2 else { return [coordinates] }
        
        let strongTurnMinDistance: CLLocationDistance = 30 // meters
        let speedThreshold: CLLocationSpeed = 8.0 // m/s (~18 mph)
        let speedWindowSize = 5
        
        var segments: [[LocationPoint]] = []
        var currentSegment: [LocationPoint] = [coordinates[0]]
        
        var stableBearing: Double? = nil
        var inTurn = false
        
        var speedWindow: [CLLocationSpeed] = []
        
        for i in 1..<coordinates.count {
            let prev = coordinates[i-1]
            let curr = coordinates[i]
            let bearing = self.bearing(from: prev, to: curr)
            
            // Calculate distance between prev and curr points
            let distance = curr.distance(to: prev)
            
            // Update speed window
            if curr.speed >= 0 {
                speedWindow.append(curr.speed)
                if speedWindow.count > speedWindowSize {
                    speedWindow.removeFirst()
                }
            }
            let averageSpeed = averageSpeed(from: speedWindow)
            
            if let lastStable = stableBearing {
                var bearingDiff = abs(bearing - lastStable)
                if bearingDiff > 180 { bearingDiff = 360 - bearingDiff }
                
                if inTurn {
                    // If heading has normalized, end the segment here
                    if bearingDiff < bearingThreshold {
                        segments.append(currentSegment)
                        currentSegment = [curr]
                        stableBearing = bearing
                        inTurn = false
                        speedWindow.removeAll()
                    } else {
                        // Still turning, keep adding points
                        currentSegment.append(curr)
                    }
                } else {
                    // Only consider as a strong turn if bearing difference exceeds threshold AND distance between points is less than or equal to strongTurnMinDistance
                    // AND average speed in window is below speed threshold
                    if bearingDiff >= bearingThreshold && distance <= strongTurnMinDistance && averageSpeed < speedThreshold {
                        // Start of a strong, rapid turn
                        inTurn = true
                        currentSegment.append(curr)
                    } else {
                        // Still straight or gradual curve, keep adding, update stable bearing
                        currentSegment.append(curr)
                        stableBearing = bearing
                    }
                }
            } else {
                stableBearing = bearing
                currentSegment.append(curr)
            }
        }
        // Don't forget to append the last segment
        if !currentSegment.isEmpty {
            segments.append(currentSegment)
        }
        return segments
    }
    
    // MARK: - Utility Method: Remove duplicate consecutive coordinates
    
    /// Removes consecutive duplicate coordinates from the array.
    /// - Parameter coords: The array of coordinates.
    /// - Returns: Cleaned array without consecutive duplicates.
    private static func removeDuplicateConsecutiveCoordinates(from coords: [LocationPoint]) -> [LocationPoint] {
        guard !coords.isEmpty else { return [] }
        
        var cleaned: [LocationPoint] = [coords[0]]
        for coord in coords.dropFirst() {
            if coord.coordinate.latitude != cleaned.last!.coordinate.latitude || coord.coordinate.longitude != cleaned.last!.coordinate.longitude {
                cleaned.append(coord)
            }
        }
        return cleaned
    }
    
    // MARK: - Private Helper: Average Speed
    
    /// Computes the average speed from a list of speeds.
    /// - Parameter speeds: Array of CLLocationSpeed values.
    /// - Returns: Average speed.
    private static func averageSpeed(from speeds: [CLLocationSpeed]) -> CLLocationSpeed {
        guard !speeds.isEmpty else { return 0 }
        let total = speeds.reduce(0, +)
        return total / Double(speeds.count)
    }
    
    
    // MARK: - Distance Accumulators (MKD + Raw)
    private static func cumulativeDistances(for coords: [CLLocationCoordinate2D]) -> [CLLocationDistance] {
        guard !coords.isEmpty else { return [] }
        var cum = Array(repeating: 0.0 as CLLocationDistance, count: coords.count)
        for i in 1..<coords.count {
            cum[i] = cum[i-1] + coords[i-1].distance(to: coords[i])
        }
        return cum
    }

    private static func cumulativeRawDistances(for pts: [LocationPoint]) -> [CLLocationDistance] {
        guard !pts.isEmpty else { return [] }
        var cum = Array(repeating: 0.0 as CLLocationDistance, count: pts.count)
        for i in 1..<pts.count {
            cum[i] = cum[i-1] + pts[i-1].distance(to: pts[i])
        }
        return cum
    }

    // MARK: - Enrich MKD with Raw Metadata (Monotone Projection)
    /// Maps each MKDirections vertex to a monotone position along the raw path (by cumulative distance)
    /// and interpolates timestamp/speed/course from the bracketing raw samples. Geometry comes from MKD.
    private static func enrichClippedMonotone(mkd: [CLLocationCoordinate2D], raw: [LocationPoint]) -> [LocationPoint] {
        guard !mkd.isEmpty else { return [] }
        guard raw.count >= 2 else {
            // Fallback: keep geometry with minimal metadata
            return mkd.map { LocationPoint(CLLocation(latitude: $0.latitude, longitude: $0.longitude)) }
        }

        let rawCum = cumulativeRawDistances(for: raw)
        let mkdCum = cumulativeDistances(for: mkd)

        func ts(_ p: LocationPoint) -> TimeInterval { p.timestamp.timeIntervalSinceReferenceDate }

        var out: [LocationPoint] = []
        out.reserveCapacity(mkd.count)

        var i0 = 0
        var i1 = 1

        for j in 0..<mkd.count {
            let s = mkdCum[j]

            // Advance the raw bracket to enclose s (monotone, no backtracking)
            while i1 < raw.count && rawCum[i1] < s { i0 = i1; i1 += 1 }
            if i1 >= raw.count { i0 = max(0, raw.count - 2); i1 = raw.count - 1 }

            let segLen  = max(0.0, rawCum[i1] - rawCum[i0])
            let segTime = max(0.0, ts(raw[i1])  - ts(raw[i0]))
            let t: Double = segLen > 0 ? min(max((s - rawCum[i0]) / segLen, 0), 1) : 0

            // Timestamp interpolation (preserves raw pacing)
            let interpTS   = ts(raw[i0]) + t * segTime
            let interpDate = Date(timeIntervalSinceReferenceDate: interpTS)

            // Speed from raw pacing for this interval (handles pauses naturally)
            let speed: CLLocationSpeed = segTime > 0 ? segLen / segTime : 0

            // Course from raw segment; fallback to previous if degenerate
            var course: CLLocationDirection = TripOptimizer.bearing(from: raw[i0], to: raw[i1])
            if segLen < 0.5, j > 0 { course = out[j-1].course }

            let loc = CLLocation(
                coordinate: mkd[j],
                altitude: 0,
                horizontalAccuracy: kCLLocationAccuracyHundredMeters, // synthetic placeholders
                verticalAccuracy:   kCLLocationAccuracyHundredMeters,
                course: course,
                speed:  speed,
                timestamp: interpDate
            )
            out.append(LocationPoint(loc))
        }
        return out
    }
}

// MARK: - MKPolyline Extension to extract coordinates

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}

private extension CLLocationCoordinate2D {
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let loc1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let loc2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return loc1.distance(from: loc2)
    }
}

// MARK: - Clip Final Path Helper (Tail Window, Backward Scan)
/// Uses the last N raw coordinates as a tail window and searches backward through the MKD path
/// (starting a few vertices from the end) for the last entry into that tail corridor. When found,
/// it nudges forward up to two vertices (if still within tolerance) and clips there.
private func clipFinalPath(
    _ optimized: [CLLocationCoordinate2D],
    rawTail: [CLLocationCoordinate2D],
    toleranceMeters tol: CLLocationDistance = 20,
    probeOffset: Int = 3,
    appendTolMeters: CLLocationDistance = 5
) -> [CLLocationCoordinate2D] {
    let n = optimized.count
    guard n >= probeOffset + 1, !rawTail.isEmpty else { return optimized }

    // Distance-to-any of the tail points within tol
    @inline(__always) func nearTail(_ p: CLLocationCoordinate2D) -> Bool {
        for r in rawTail { if p.distance(to: r) <= tol { return true } }
        return false
    }

    // Start probing a few points from the end (to avoid immediate overshoot contact at the very end)
    let start = n - probeOffset
    var i = start
    print("clipFinalPath: scanning from i=\(start) down to 0, tailSize=\(rawTail.count), tol=\(Int(tol))m")

    // If probe area already aligns with tail, attempt to walk forward toward end
    if nearTail(optimized[i]) {
        var cand = i
        while cand + 1 < n, nearTail(optimized[cand + 1]) { cand += 1 }
        if cand >= n - 1 {
            print("clipFinalPath: tail corridor reaches path end — keeping full path")
            return optimized
        } else {
            print("clipFinalPath: aligned near end, clipping at cand=\(cand)")
            return Array(optimized.prefix(cand + 1))
        }
    }

    // Otherwise, backtrack to find the last entry into the tail corridor
    while i >= 0 {
        if nearTail(optimized[i]) {
            var cand = i
            // Walk forward while we remain inside the tail corridor; stop on first miss
            while cand + 1 < n && nearTail(optimized[cand + 1]) { cand += 1 }
            
            print("clipFinalPath: backtracked match at i=\(i), clipping at cand=\(cand)")
            print("clipFinalPath: aligned near end, clipping at cand=\(cand)")
            var clipped = Array(optimized.prefix(cand + 1))
            if let rawLast = rawTail.last, let lastKept = clipped.last {
                let gap = lastKept.distance(to: rawLast)
                if gap > appendTolMeters {
                    clipped.append(rawLast)
                    print("clipFinalPath: appended rawLast (gap=\(Int(gap))m) [backtrack branch]")
                } else {
                    print("clipFinalPath: no append; gap=\(Int(gap))m ≤ \(Int(appendTolMeters))m [backtrack branch]")
                }
                return clipped
            }
        }
        i -= 1
    }

    print("clipFinalPath: no tail-window match — returning original")
    return optimized
}

