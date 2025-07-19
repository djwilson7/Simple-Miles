//  MockTripSessionStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//
//  Mock implementation conforming to TripSessionStoringProtocol for injection into view models and robust test assertions.

import Foundation
@testable import SimpleMiles

final class MockTripSessionStore: TripSessionStoringProtocol {
    var mockTrips: [TripSessionModel] = []
    private var updateCounts: [UUID: Int] = [:]

    func fetchAll() -> [TripSessionModel] {
        mockTrips
    }

    func save(_ model: TripSessionModel) {
        mockTrips.append(model)
    }

    func delete(sessionID: UUID) {
        mockTrips.removeAll { $0.id == sessionID }
    }

    func update(_ updatedTrip: TripSessionModel) {
        guard let idx = mockTrips.firstIndex(where: { $0.id == updatedTrip.id }) else { return }
        mockTrips[idx] = updatedTrip
        updateCounts[updatedTrip.id, default: 0] += 1
    }

    func clearAll() {
        mockTrips.removeAll()
    }

    func updateCallCount(for id: UUID) -> Int {
        return updateCounts[id] ?? 0
    }
}

