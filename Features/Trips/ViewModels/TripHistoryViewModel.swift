//
//  TripHistoryViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class TripHistoryViewModel: ObservableObject {
    @Published private(set) var sessions: [TripSessionModel] = []

    private let store: TripSessionStoringProtocol

    init(store: TripSessionStoringProtocol = TripSessionStore()) {
        self.store = store
        load()
    }

    func load() {
        print("[TripHistoryViewModel] load triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        sessions = store.fetchAll()
    }

    func delete(sessionID: UUID) {
        print("[TripHistoryViewModel] delete triggered for sessionID: \(sessionID)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        store.delete(sessionID: sessionID)
        load()
    }
}
