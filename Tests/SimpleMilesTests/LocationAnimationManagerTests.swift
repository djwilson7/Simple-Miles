import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("LocationAnimationManager Tests")
struct LocationAnimationManagerTests {
    
    @MainActor
    @Test("Basic animation call")
    func testAnimate() async throws {
        let manager = LocationAnimationManager()
        let start = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 0)
        let end = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 10, course: 0)
        
        var updateCount = 0
        manager.animate(from: start, to: end, travelStateIsTraveling: false) { _, _ in
            updateCount += 1
        }
        
        #expect(updateCount == 1) // Immediate update when not traveling
    }
    
    @MainActor
    @Test("Too close to animate with anchors")
    func testAnchors() {
        let manager = LocationAnimationManager()
        let p = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 0)
        
        // Static last anchor
        manager.updateAnchors(live: nil, staticLast: p)
        var updated = false
        manager.animate(from: p, to: p, travelStateIsTraveling: true) { _, tail in
            if !tail.isEmpty { updated = true }
        }
        #expect(updated)
        
        // Live anchor
        manager.updateAnchors(live: p, staticLast: nil)
        updated = false
        manager.animate(from: p, to: p, travelStateIsTraveling: true) { _, tail in
            if !tail.isEmpty { updated = true }
        }
        #expect(updated)
    }
    
    @MainActor
    @Test("No start point")
    func testNoStart() {
        let manager = LocationAnimationManager()
        let end = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 10, course: 0)
        
        var updated = false
        manager.animate(from: nil, to: end, travelStateIsTraveling: true) { _, _ in
            updated = true
        }
        #expect(updated)
    }
    
    @MainActor
    @Test("Mid-flight retargeting details")
    func testRetargetDetails() async throws {
        let manager = LocationAnimationManager()
        let start = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 0)
        let mid = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 10, course: 0)
        let end = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 2, longitude: 2), timestamp: Date(), speed: 10, course: 0)
        
        manager.animate(from: start, to: mid, travelStateIsTraveling: true) { _, _ in }
        
        // Mock progress
        manager.animationStartTime = Date().addingTimeInterval(-0.4)
        manager.animationDuration = 0.8
        
        // This should hit the mid-flight position calculation branch
        manager.animate(from: mid, to: end, travelStateIsTraveling: true) { _, _ in }
        
        #expect(manager.isAnimating)
        #expect(manager.animationStartLocation != nil)
        
        manager.reset()
        #expect(!manager.isAnimating)
    }

    @MainActor
    @Test("Too close to animate distance check")
    func testTooCloseToAnimate() {
        let manager = LocationAnimationManager()
        let start = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 0)
        let end = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0.000001, longitude: 0.000001), timestamp: Date(), speed: 10, course: 0) // Very close
        var updateCount = 0
        manager.animate(from: start, to: end, travelStateIsTraveling: true) { _, _ in
            updateCount += 1
        }
        #expect(updateCount == 1) // Publish immediately
    }

    @MainActor
    @Test("Handle timer tick completion")
    func testHandleTimerTickCompletion() {
        let manager = LocationAnimationManager()
        let start = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), timestamp: Date(), speed: 10, course: 0)
        let end = LocationPoint(coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 1), timestamp: Date(), speed: 10, course: 0)
        
        manager.animationStartLocation = start
        manager.animationTargetLocation = end
        manager.animationStartTime = Date().addingTimeInterval(-2)
        manager.animationDuration = 1
        manager.animationTimer = Timer()
        manager.animationOnUpdate = { _, _ in }
        
        manager.handleTimerTick(Timer())
        #expect(manager.animationTimer == nil)
    }

    @MainActor
    @Test("Handle timer tick nil properties")
    func testHandleTimerTickNil() {
        let manager = LocationAnimationManager()
        manager.animationTimer = Timer()
        manager.handleTimerTick(Timer())
        #expect(manager.animationTimer == nil)
    }
}
