//
//  TripHistoryViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class TripHistoryViewModel: ObservableObject {

    // MARK: - Published Output

    @Published private(set) var sessions: [TripSessionModel] = []

    // MARK: - Dependencies

    private let store: TripSessionStoringProtocol
    
    init(store: TripSessionStoringProtocol = TripSessionStore()) {
        self.store = store
        load()
    }

    // MARK: - Init

    init(store: TripSessionStore = TripSessionStore()) {
        self.store = store
        load()
    }

    // MARK: - Public Actions

    func load() {
        sessions = store.fetchAll()
    }

    func delete(sessionID: UUID) {
        store.delete(sessionID: sessionID)
        load()
    }
}
