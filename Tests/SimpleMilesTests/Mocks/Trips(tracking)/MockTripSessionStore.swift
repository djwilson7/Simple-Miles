//
//  MockTripSessionStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/16/25.
//

import Foundation
@testable import SimpleMiles

final class MockTripSessionStore: TripSessionStoringProtocol {
    var mockTrips: [TripSessionModel] = []

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
        guard let index = mockTrips.firstIndex(where: { $0.id == updatedTrip.id }) else { return }
        mockTrips[index] = updatedTrip
    }

    func clearAll() {
        mockTrips.removeAll()
    }
}
