import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

    @MainActor
    @Test("Update anchors branches")
    func testAnchorBranches() {
        let manager = LocationAnimationManager()
        let p = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 37, longitude: -122), timestamp: Date(), speed: 0, course: 0)
        
        manager.updateAnchors(live: p, staticLast: nil)
        #expect(manager.currentLiveAnchor?.latitude == 37)
        
        manager.updateAnchors(live: nil, staticLast: p)
        #expect(manager.currentStaticLast?.latitude == 37)
        
        manager.updateAnchors(live: nil, staticLast: nil)
        #expect(manager.currentLiveAnchor == nil)
    }
