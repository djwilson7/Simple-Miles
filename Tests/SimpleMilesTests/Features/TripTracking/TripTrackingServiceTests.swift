// TripTrackingServiceTests.swift
// SimpleMiles

import XCTest
import CoreLocation
import Combine
@testable import SimpleMiles

final class TripTrackingServiceTests: XCTestCase {
    private var service: TripTrackingService!
    private var mockLifecycle: MockTripLifecycleManager!
    private var mockPersistence: MockTripPersistenceManager!
    private var mockMonitor: MockMovementMonitor!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        mockLifecycle = MockTripLifecycleManager()
        mockPersistence = MockTripPersistenceManager()
        mockMonitor = MockMovementMonitor()

        service = TripTrackingService(
            lifecycleManager: mockLifecycle,
            persistenceManager: mockPersistence,
            movementMonitor: mockMonitor
        )
    }

    func test_startRecording_initializesSessionAndStatus() {
        service.startRecording()

        XCTAssertTrue(mockLifecycle.didStartSession)
        XCTAssertEqual(service.status, .recording)
        XCTAssertEqual(service.currentSession, mockLifecycle.mockSession)
    }

    func test_stopRecording_aggregatesPathAndSaves() {
        let mockState = MockTripRecordingState()
        let recorder = TripPathRecorder()
        let session = MockTripSessionModel.make()
        mockLifecycle.mockSession = session

        service = TripTrackingService(
            lifecycleManager: mockLifecycle,
            pathRecorder: recorder,
            persistenceManager: mockPersistence,
            movementMonitor: mockMonitor,
            recordingState: mockState
        )

        service.startRecording()

        let loc1 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 10.0,
            timestamp: Date()
        )

        let loc2 = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 1.0, longitude: 2.0),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 10.0,
            timestamp: Date().addingTimeInterval(1)
        )

        service.locationManager(CLLocationManager(), didUpdateLocations: [loc1])
        service.locationManager(CLLocationManager(), didUpdateLocations: [loc2])
        service.stopRecording()

        XCTAssertTrue(mockLifecycle.didStopSession)
        XCTAssertTrue(mockPersistence.didSave)
        XCTAssertEqual(mockPersistence.savedTrip?.path.count, 2)
        XCTAssertGreaterThan(mockPersistence.savedTrip?.distance ?? 0, 0)
        XCTAssertNil(service.currentSession)
        XCTAssertEqual(service.status, .idle)
    }



    func test_resumeRecording_restoresSessionAndStatus() {
        let session = MockTripSessionModel.make()
        service.resumeRecording(from: session)

        XCTAssertEqual(service.currentSession, session)
        XCTAssertEqual(service.status, .recording)
    }

    func test_clearAllTrips_callsPersistenceManager() {
        service.clearAllTrips()
        XCTAssertTrue(mockPersistence.didClear)
    }

    func test_updateAnalyzerThresholds_forwardsToMonitor() {
        service.updateAnalyzerThresholds(speed: 6.0, distance: 25.0)
        XCTAssertEqual(mockMonitor.lastSpeed, 6.0)
        XCTAssertEqual(mockMonitor.lastDistance, 25.0)
    }

    func test_startPassiveMonitoring_startsMonitoringAndLocation() {
        service.startPassiveMonitoring()
        XCTAssertTrue(mockMonitor.didStartPassive)
    }

    func test_locationManager_didUpdate_appendsPathAndPublishesSession() {
        let mockState = MockTripRecordingState()
        let recorder = TripPathRecorder()
        mockLifecycle.mockSession = MockTripSessionModel.make()

        service = TripTrackingService(
            lifecycleManager: mockLifecycle,
            pathRecorder: recorder,
            persistenceManager: mockPersistence,
            movementMonitor: mockMonitor,
            recordingState: mockState
        )

        service.startRecording()

        let expectation = XCTestExpectation(description: "Session updated")

        service.currentSessionPublisher
            .dropFirst()
            .sink { session in
                if session?.path.count == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        let loc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 1.1, longitude: 1.1),
            altitude: 0,
            horizontalAccuracy: 5,
            verticalAccuracy: 5,
            course: 0,
            speed: 10.0,
            timestamp: Date()
        )

        service.locationManager(CLLocationManager(), didUpdateLocations: [loc])

        wait(for: [expectation], timeout: 1.0)
    }


    func test_movementMonitor_onShouldStartTrip_startsSession() {
        mockMonitor.onShouldStartTrip?()
        XCTAssertEqual(service.status, .recording)
        XCTAssertTrue(mockLifecycle.didStartSession)
    }

    func test_movementMonitor_onShouldPauseTrip_triggersPause() {
        mockLifecycle.mockSession = MockTripSessionModel.make()
        service.startRecording()

        mockMonitor.onShouldPauseTrip?()

        XCTAssertEqual(service.status, .paused)
        XCTAssertFalse(service.recordingState.isRecording)
    }

    func test_movementMonitor_onShouldResumeTrip_triggersResume() {
        let mockState = MockTripRecordingState()
        let recorder = TripPathRecorder()
        mockLifecycle.mockSession = MockTripSessionModel.make()

        service = TripTrackingService(
            lifecycleManager: mockLifecycle,
            pathRecorder: recorder,
            persistenceManager: mockPersistence,
            movementMonitor: mockMonitor,
            recordingState: mockState
        )

        service.startRecording()
        service.pauseTracking()

        mockMonitor.onShouldResumeTrip?()

        XCTAssertEqual(service.status, .recording)
        XCTAssertTrue(mockState.isRecording)
    }


    func test_movementMonitor_onShouldStopTrip_triggersStopRecording() {
        mockLifecycle.mockSession = MockTripSessionModel.make()
        service.startRecording()

        let coord1 = CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
        let coord2 = CLLocationCoordinate2D(latitude: 1.0, longitude: 2.0)

        service.locationManager(CLLocationManager(), didUpdateLocations: [
            CLLocation(latitude: coord1.latitude, longitude: coord1.longitude),
            CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        ])

        mockMonitor.onShouldStopTrip?()

        XCTAssertTrue(mockPersistence.didSave)
        XCTAssertEqual(service.status, .idle)
    }
}
