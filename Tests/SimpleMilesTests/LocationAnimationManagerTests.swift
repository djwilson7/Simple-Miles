import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("LocationAnimationManager Tests")
struct LocationAnimationManagerTests {
    
    @MainActor
    @Test("Spline smoothness")
    func testSplineSmoothness() {
        let manager = LocationAnimationManager()
        let gt0 = CLLocationCoordinate2D(latitude: 0, longitude: -0.001)
        let gt1 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let puck = CLLocationCoordinate2D(latitude: 0.001, longitude: 0.001)
        
        let tail = manager.generateSplineTail(groundTruth: [gt0, gt1], puck: puck)
        
        #expect(tail.count == 26)
        
        for i in 1..<tail.count {
            let pPrev = tail[i-1]
            let pCurr = tail[i]
            let dist = CLLocation(latitude: pPrev.latitude, longitude: pPrev.longitude)
                .distance(from: CLLocation(latitude: pCurr.latitude, longitude: pCurr.longitude))
            
            // Total distance is ~220m. 16 points means ~15m per segment.
            #expect(dist < 50) 
        }
    }
    
    @MainActor
    @Test("Reset is no-op")
    func testReset() {
        let manager = LocationAnimationManager()
        manager.reset() // Should not crash
    }
}
