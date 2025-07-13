//
//  MockMovementAnalyzer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation
import CoreLocation
@testable import SimpleMiles

final class MockMovementAnalyzer: MovementAnalyzing {
    
    // MARK: - Stubbed return values for test control
    var isMovingResult: Bool = true
    var isStayingStoppedResult: Bool = false
    var shouldStartTripResult: Bool = true
    var shouldStopTripResult: Bool = false
    
    // MARK: - Protocol Conformance
    
    func isMoving(speed: CLLocationSpeed?) -> Bool {
        return isMovingResult
    }
    
    func isStayingStopped(for durations: [TimeInterval]) -> Bool {
        return isStayingStoppedResult
    }
    
    func shouldStartTrip(speed: CLLocationSpeed?, acceleration: Double?) -> Bool {
        return shouldStartTripResult
    }
    
    func shouldStopTrip(recentIdleDurations: [TimeInterval], speed: CLLocationSpeed?, acceleration: Double?) -> Bool {
        return shouldStopTripResult
    }
}
