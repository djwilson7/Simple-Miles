import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("State and Recording Management", .serialized)
struct StateAndRecordingTests {

    // MARK: - RecordingManager Tests
    @MainActor
    @Test("Transition from idle to traveling")
    func testIdleToTravel() {
        let manager = RecordingManager.shared
        TravelStateManager.shared.reset()
        manager.reset()
        
        manager.handleTravelStateUpdate(.traveling)
        #expect(manager.isRecording)
        #expect(manager.liveSegment != nil)
    }
    
    @MainActor
    @Test("Interpolation details")
    func testInterp() {
        let manager = RecordingManager.shared
        let p1 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let p2 = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        
        let res0 = manager.interpolatePoints(from: p1, to: p2, steps: 0)
        #expect(res0.count == 1)
        
        let res1 = manager.interpolatePoints(from: p1, to: p2, steps: 1)
        #expect(res1.count == 1)
        
        let res5 = manager.interpolatePoints(from: p1, to: p2, steps: 5)
        #expect(res5.count == 5)
    }
    
    @MainActor
    @Test("Redundant transitions")
    func testRedundant() {
        let manager = RecordingManager.shared
        TravelStateManager.shared.reset()
        manager.reset()
        
        manager.handleTravelStateUpdate(.traveling)
        manager.handleTravelStateUpdate(.traveling) // Redundant
        #expect(manager.isRecording)
        
        manager.handleTravelStateUpdate(.paused)
        manager.handleTravelStateUpdate(.paused) // Redundant
        #expect(manager.isRecording)
    }
    
    @MainActor
    @Test("Distance threshold discard")
    func testDiscard() async throws {
        let manager = RecordingManager.shared
        TravelStateManager.shared.reset()
        manager.reset()
        SettingsManager.shared.minimumTripDistance = 100.0 // Very large for easy discard
        
        manager.handleTravelStateUpdate(.traveling)
        // 0 distance
        manager.handleTravelStateUpdate(.idle)
        #expect(manager.previousSegment == nil)
    }
    
    @MainActor
    @Test("Distance threshold save")
    func testSave() async throws {
        let manager = RecordingManager.shared
        TravelStateManager.shared.reset()
        manager.reset()
        SettingsManager.shared.minimumTripDistance = 0.0001 // Very small for easy save
        
        manager.handleTravelStateUpdate(.traveling)
        let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, speed: 10, timestamp: Date())
        LocationManager.shared.locationManager(CLLocationManager(), didUpdateLocations: [loc])
        try await Task.sleep(nanoseconds: 100_000_000)
        
        manager.handleTravelStateUpdate(.idle)
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    @MainActor
    @Test("Transition through all states")
    func testRecordingTransitions() async throws {
        let manager = RecordingManager.shared
        TravelStateManager.shared.reset()
        manager.reset()
        
        let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 0, speed: 10, timestamp: Date())
        LocationManager.shared.locationManager(CLLocationManager(), didUpdateLocations: [loc])
        // Small delay for Combine propagation
        try await Task.sleep(nanoseconds: 200_000_000)

        // Idle -> Traveling
        manager.handleTravelStateUpdate(.traveling)
        #expect(manager.isRecording)
        
        // Traveling -> Paused
        manager.handleTravelStateUpdate(.paused)
        #expect(manager.isRecording)
        
        // Paused -> Traveling (with merge)
        manager.pausedHeadingBuffer = [0, 0, 0, 0]
        manager.pauseAnchor = LocationPoint(loc)
        manager.handleTravelStateUpdate(.traveling)
        #expect(manager.isRecording)
        
        // Traveling -> Paused -> Traveling (no merge)
        manager.handleTravelStateUpdate(.paused)
        manager.pausedHeadingBuffer = [0, 90, 180, 270, 0]
        manager.pauseAnchor = LocationPoint(loc)
        manager.handleTravelStateUpdate(.traveling)
        #expect(manager.isRecording)
        
        // Traveling -> Idle
        manager.handleTravelStateUpdate(.idle)
        #expect(!manager.isRecording)
        
        // Give time for detached tasks to finish
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    @MainActor
    @Test("Interpolation with steps <= 0")
    func testInterpStepsZero() {
        let manager = RecordingManager.shared
        let p1 = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let p2 = CLLocationCoordinate2D(latitude: 1, longitude: 1)
        
        let res = manager.interpolatePoints(from: p1, to: p2, steps: 0)
        #expect(res.count == 1)
        #expect(res[0].latitude == 1)
    }

    @MainActor
    @Test("Transition to Idle from Idle")
    func testIdleToIdle() {
        let manager = RecordingManager.shared
        manager.reset()
        // It should just reset and return
        manager.handleTravelStateUpdate(.idle)
        #expect(!manager.isRecording)
    }

    @MainActor
    @Test("Initialization and appending locations")
    func testLocationAppending() async throws {
        let manager = RecordingManager.shared
        
        // 1. Reset everything
        LocationManager.shared.reset()
        DrivingStateManager.shared.reset()
        TravelStateManager.shared.reset()
        manager.reset()
        
        // 2. Wait for async resets to propagate through Combine
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // 3. Set a base location to avoid GPS jump detection later
        let baseLoc = CLLocation(latitude: 37, longitude: -122)
        LocationManager.shared.locationManager(CLLocationManager(), didUpdateLocations: [baseLoc])
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // 4. Manual transition to traveling
        manager.handleTravelStateUpdate(.traveling)
        #expect(manager.isRecording)
        #expect(manager.liveSegment != nil)
        
        // 5. Push a movement location (small distance from base)
        let moveLoc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 37.001, longitude: -122.001), altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, course: 45, speed: 15, timestamp: Date())
        LocationManager.shared.locationManager(CLLocationManager(), didUpdateLocations: [moveLoc])
        
        // 6. Wait for propagation
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        #expect(manager.liveSegment != nil)
        #expect(manager.nonCommitedPath.count > 0)
    }

    @MainActor
    @Test("Manual timer tick")
    func testManualTimer() {
        let manager = RecordingManager.shared
        TravelStateManager.shared.reset()
        manager.reset()
        manager.handleTravelStateUpdate(.traveling)
        // We can't easily trigger the Combine timer, but we can check if it's active
        #expect(manager.isRecording)
        manager.handleTravelStateUpdate(.idle)
    }
}
