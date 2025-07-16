//
//  MockTripSessionStore.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
@testable import SimpleMiles

final class MockTripSessionStore: TripSessionStoringProtocol {
    // MARK: - Test State
    var stubbedSessions: [TripSessionModel] = []
    var deletedIDs: [UUID] = []
    var didFetchAfterDelete = false
    var savedModels: [TripSessionModel] = []
    var updatedModels: [TripSessionModel] = []

    // MARK: - Protocol Conformance
    func fetchAll() -> [TripSessionModel] {
        didFetchAfterDelete = true
        return stubbedSessions
    }

    func save(_ model: TripSessionModel) {
        savedModels.append(model)
    }

    func delete(sessionID: UUID) {
        if stubbedSessions.contains(where: { $0.id == sessionID }) {
            deletedIDs.append(sessionID)
            stubbedSessions.removeAll { $0.id == sessionID }
        }
    }

    func update(_ updatedTrip: TripSessionModel) {
        updatedModels.append(updatedTrip)
    }
}
