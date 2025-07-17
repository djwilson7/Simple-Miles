//
//  TripTrackingServiceTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import XCTest
import CoreLocation
import Combine
@testable import SimpleMiles

final class TripTrackingServiceTests: XCTestCase {
    private var service: TripTrackingService!
    private var mockLifecycle: MockTripLifecycleManager!
    private var mockRecorder: MockTripSegmentRecorder!
    private var mockPersistence: MockTripPersistenceManager!
    private var mockMonitor: MockMovementMonitor!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        mockLifecycle = MockTripLifecycleManager()
        mockRecorder = MockTripSegmentRecorder()
        mockPersistence = MockTripPersistenceManager()
        mockMonitor = MockMovementMonitor()

        service = TripTrackingService(
            lifecycleManager: mockLifecycle,
            segmentRecorder: mockRecorder,
            persistenceManager: mockPersistence,
            movementMonitor: mockMonitor
        )
    }

    func test_startRecording_triggersLifecycleResetAndState() {
        service.startRecording()

        XCTAssertTrue(mockLifecycle.didStartSession)
        XCTAssertEqual(service.currentSession, mockLifecycle.mockSession)
        XCTAssertTrue(mockRecorder.didReset)
        XCTAssertTrue(mockMonitor.didResetState)
    }

    func test_stopRecording_savesTripWithAggregatedDistance() {
        let id = UUID()
        let baseSession = MockTripSessionModel.make(id: id)
        mockLifecycle.mockSession = baseSession
        mockRecorder.mockSegments = [
            MockTripSegmentModel.make(distance: 50),
            MockTripSegmentModel.make(distance: 70)
        ]

        service.startRecording()
        service.stopRecording()

        XCTAssertTrue(mockLifecycle.didStopSession)
        XCTAssertTrue(mockPersistence.didSave)
        XCTAssertEqual(mockPersistence.savedTrip?.id, id)
        XCTAssertEqual(mockPersistence.savedTrip?.segments.count, 2)
        XCTAssertEqual(mockPersistence.savedTrip?.distance, 120)
        XCTAssertNil(service.currentSession)
    }

    func test_resumeRecording_restoresSessionAndRestartsLocation() {
        let session = MockTripSessionModel.make()
        service.resumeRecording(from: session)

        XCTAssertEqual(service.currentSession, session)
    }

    func test_clearAllTrips_triggersPersistenceClear() {
        service.clearAllTrips()
        XCTAssertTrue(mockPersistence.didClear)
    }

    func test_updateThresholds_propagatesToMonitor() {
        service.updateAnalyzerThresholds(speed: 4.2, distance: 88.0)
        XCTAssertEqual(mockMonitor.lastSpeed, 4.2)
        XCTAssertEqual(mockMonitor.lastDistance, 88.0)
    }

    func test_startPassiveMonitoring_triggersMonitor() {
        service.startPassiveMonitoring()
        XCTAssertTrue(mockMonitor.didStartPassive)
    }

    func test_locationManager_didUpdate_updatesSegmentAndAnalyzes() {
        mockLifecycle.mockSession = MockTripSessionModel.make()
        service.startRecording()

        let location = CLLocation(latitude: 1.0, longitude: 1.0)
        service.locationManager(CLLocationManager(), didUpdateLocations: [location])

        XCTAssertTrue(mockRecorder.didBeginSegment || mockRecorder.didCompleteSegment)
        XCTAssertTrue(mockMonitor.didAnalyze)
    }

    func test_movementMonitor_onShouldResumeTrip_triggersResume() {
        let session = MockTripSessionModel.make()
        mockLifecycle.mockSession = session
        mockMonitor.onShouldResumeTrip?()

        XCTAssertEqual(service.currentSession, session)
    }

    func test_movementMonitor_onShouldStartTrip_triggersStart() {
        mockMonitor.onShouldStartTrip?()
        XCTAssertTrue(mockLifecycle.didStartSession)
    }

    func test_movementMonitor_onShouldPauseTrip_triggersStop() {
        let id = UUID()
        mockLifecycle.mockSession = MockTripSessionModel.make(id: id)
        mockRecorder.mockSegments = [MockTripSegmentModel.make(distance: 123)]

        service.startRecording()
        mockMonitor.onShouldPauseTrip?()

        XCTAssertTrue(mockLifecycle.didStopSession)
        XCTAssertEqual(mockPersistence.savedTrip?.id, id)
    }
}
