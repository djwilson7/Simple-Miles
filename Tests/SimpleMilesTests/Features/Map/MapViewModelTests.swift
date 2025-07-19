//  MapViewModelTests.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Covers: loading of all path points with and without filter, correct filtering by TripType, empty state, and store integration.
//  The suite validates segment/path aggregation logic for both typical and edge scenarios, ensuring correct published value updates under all supported input conditions.

import XCTest
import Combine
@testable import SimpleMiles

final class MapViewModelTests: XCTestCase {
    private var viewModel: MapViewModel!
    private var mockStore: MockTripSessionStore!
    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        mockStore = MockTripSessionStore()
    }

    override func tearDown() {
        viewModel = nil
        mockStore = nil
        cancellables.removeAll()
        super.tearDown()
    }

    // MARK: - Basic Functionality

    func test_loadPathPoints_withoutFilter_loadsAllPoints() {
        let coord1 = CoordinateModel(latitude: 10, longitude: 10)
        let coord2 = CoordinateModel(latitude: 20, longitude: 20)
        let session1 = MockTripSessionModel.make(path: [coord1])
        let session2 = MockTripSessionModel.make(path: [coord2])
        mockStore.mockTrips = [session1, session2]

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints()

        XCTAssertEqual(viewModel.pathPoints, [coord1, coord2])
    }

    func test_loadPathPoints_withTypeFilter_loadsOnlyMatchingPoints() {
        let businessCoord = CoordinateModel(latitude: 10, longitude: 10)
        let personalCoord = CoordinateModel(latitude: 30, longitude: 30)
        let businessSession = MockTripSessionModel.make(tripType: .business, path: [businessCoord])
        let personalSession = MockTripSessionModel.make(tripType: .personal, path: [personalCoord])
        mockStore.mockTrips = [businessSession, personalSession]

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints(filter: .business)

        XCTAssertEqual(viewModel.pathPoints, [businessCoord])
    }

    func test_loadPathPoints_withNonMatchingType_resultsInEmpty() {
        let session = MockTripSessionModel.make(tripType: .personal, path: [CoordinateModel(latitude: 40, longitude: 40)])
        mockStore.mockTrips = [session]

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints(filter: .business)

        XCTAssertTrue(viewModel.pathPoints.isEmpty)
    }

    // MARK: - Advanced Functionality

    func test_loadPathPoints_multipleSessionsAggregatesAllPoints() {
        let c1 = CoordinateModel(latitude: 1, longitude: 1)
        let c2 = CoordinateModel(latitude: 2, longitude: 2)
        let c3 = CoordinateModel(latitude: 3, longitude: 3)
        let s1 = MockTripSessionModel.make(path: [c1, c2])
        let s2 = MockTripSessionModel.make(path: [c3])
        mockStore.mockTrips = [s1, s2]

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints()

        XCTAssertEqual(viewModel.pathPoints, [c1, c2, c3])
    }

    func test_loadPathPoints_whenNoSessions_resultsInEmpty() {
        mockStore.mockTrips = []

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints()

        XCTAssertTrue(viewModel.pathPoints.isEmpty)
    }

    func test_loadPathPoints_sessionsWithEmptyPaths_resultsInEmpty() {
        let session1 = MockTripSessionModel.make(path: [])
        let session2 = MockTripSessionModel.make(path: [])
        mockStore.mockTrips = [session1, session2]

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints()

        XCTAssertTrue(viewModel.pathPoints.isEmpty)
    }

    // MARK: - Edge Cases

    func test_loadPathPoints_withNilTypeAndEmptyStore_resultsInEmpty() {
        mockStore.mockTrips = []

        viewModel = MapViewModel(sessionStore: mockStore)
        viewModel.loadPathPoints(filter: nil)

        XCTAssertTrue(viewModel.pathPoints.isEmpty)
    }

    func test_pathPoints_publishedUpdates_whenBindLiveSessionFires() {
        let coord = CoordinateModel(latitude: 100, longitude: 100)
        let session = MockTripSessionModel.make(path: [coord])
        let mockService = MockTripTrackingService()
        viewModel = MapViewModel(sessionStore: mockStore, tripTrackingService: mockService)

        let exp = expectation(description: "Published value updates")
        var fulfilled = false

        viewModel.$pathPoints
            .dropFirst()
            .sink { points in
                if !fulfilled && points == [coord] {
                    fulfilled = true
                    XCTAssertEqual(points, [coord])
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        mockService.publishSession(session)

        wait(for: [exp], timeout: 1.0)
    }

}
