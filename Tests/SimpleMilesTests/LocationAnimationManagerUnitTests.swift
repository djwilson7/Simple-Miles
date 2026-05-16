import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("LocationAnimationManager Unit Tests")
struct LocationAnimationManagerUnitTests {
    @MainActor
    @Test("Spline generation with insufficient history")
    func testSplineInsufficientHistory() {
        let manager = LocationAnimationManager()
        let puck = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        
        // 0 points
        let tail0 = manager.generateSplineTail(groundTruth: [], puck: puck)
        #expect(tail0.count == 1)
        #expect(tail0.first?.latitude == 1)
        
        // 1 point
        let gt1 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let tail1 = manager.generateSplineTail(groundTruth: [gt1], puck: puck)
        #expect(tail1.count == 2)
        #expect(tail1[0].latitude == 0)
        #expect(tail1[1].latitude == 1)
    }

    @MainActor
    @Test("Spline generation with history")
    func testSplineWithHistory() {
        let manager = LocationAnimationManager()
        let gt0 = CLLocationCoordinate2D(latitude: -1, longitude: -1)
        let gt1 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let puck = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        
        let tail = manager.generateSplineTail(groundTruth: [gt0, gt1], puck: puck)
        
        // Should have 26 points (firstSection: 11, secondSection: 15)
        #expect(tail.count == 26)
        #expect(tail.first?.latitude == -1) // starts at second-to-last ground truth (gt0)
        #expect(tail.last?.latitude == 1)   // ends at puck (p3)
    }
}
