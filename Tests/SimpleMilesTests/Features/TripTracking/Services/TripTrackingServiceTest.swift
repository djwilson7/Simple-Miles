import XCTest
@testable import SimpleMiles
import CoreLocation


final class TripTrackingServiceTests: XCTestCase {
    
    var trackingService: TripTrackingService!
    var mockAnalyzer: MockMovementAnalyzer!

    override func setUpWithError() throws {
        mockAnalyzer = MockMovementAnalyzer()
        trackingService = TripTrackingService(analyzer: mockAnalyzer)
    }

    override func tearDownWithError() throws {
        trackingService = nil
        mockAnalyzer = nil
    }

    func mockLocation(latitude: CLLocationDegrees, longitude: CLLocationDegrees, timestamp: Date) -> CLLocation {
        let coord = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        return CLLocation(coordinate: coord, altitude: 0, horizontalAccuracy: 5, verticalAccuracy: 5, timestamp: timestamp)
    }

    func testStartRecordingInitializesSession() {
        trackingService.startRecording()
        XCTAssertNotNil(trackingService.currentSession)
        XCTAssertEqual(trackingService.currentSession?.segments.count, 0)
    }

    func testStopRecordingFinalizesSession() {
        trackingService.startRecording()
        let expectation = XCTestExpectation(description: "End trip session")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.trackingService.stopRecording()
            XCTAssertNotNil(self.trackingService.currentSession?.endTime)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    func testRecordingAppendsSegment() {
        trackingService.startRecording()

        let start = Date()
        let loc1 = mockLocation(latitude: 37.0, longitude: -122.0, timestamp: start)
        let loc2 = mockLocation(latitude: 37.0005, longitude: -122.0005, timestamp: start.addingTimeInterval(10))

        trackingService.simulate([loc1])
        trackingService.simulate([loc2])

        XCTAssertEqual(trackingService.currentSession?.segments.count, 1)
    }

    func testIdleStateTriggersTripStop() {
        trackingService.startRecording()

        let loc1 = mockLocation(latitude: 37.0, longitude: -122.0, timestamp: Date())
        trackingService.simulate([loc1])

        mockAnalyzer.shouldStopTripResult = true

        let loc2 = mockLocation(latitude: 37.0, longitude: -122.0, timestamp: Date().addingTimeInterval(60))
        trackingService.simulate([loc2])

        XCTAssertFalse(trackingService.isRecording)
    }

    func testNoSegmentWhenOnlyOnePoint() {
        trackingService.startRecording()
        let singleLoc = mockLocation(latitude: 37.0, longitude: -122.0, timestamp: Date())
        trackingService.simulate([singleLoc])
        XCTAssertEqual(trackingService.currentSession?.segments.count, 0)
    }

    func testMultipleSegmentsAddedSequentially() {
        trackingService.startRecording()
        let base = Date()
        let points = [
            mockLocation(latitude: 37.0, longitude: -122.0, timestamp: base),
            mockLocation(latitude: 37.0005, longitude: -122.0005, timestamp: base.addingTimeInterval(10)),
            mockLocation(latitude: 37.0010, longitude: -122.0010, timestamp: base.addingTimeInterval(20))
        ]
        for point in points {
            trackingService.simulate([point])
        }
        XCTAssertEqual(trackingService.currentSession?.segments.count, 2)
    }

    func testLocationUpdateSkipsNegativeAccuracy() {
        trackingService.startRecording()
        let badLoc = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            altitude: 0,
            horizontalAccuracy: -10,
            verticalAccuracy: 5,
            timestamp: Date()
        )
        trackingService.simulate([badLoc])
        XCTAssertEqual(trackingService.currentSession?.segments.count, 0)
    }
}
