//
//  MapViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class MapViewModel: ObservableObject {
    @Published var segments: [TripSegmentModel] = []

    private let sessionStore: TripSessionStoringProtocol
    private var cancellables = Set<AnyCancellable>()

    init(sessionStore: TripSessionStoringProtocol = TripSessionStore()) {
        self.sessionStore = sessionStore
        loadSegments()
    }

    func loadSegments(filter type: TripType? = nil) {
        let sessions = sessionStore.fetchAll()
        let filteredSegments = sessions.flatMap { session in
            type == nil || session.tripType == type ? session.segments : []
        }
        self.segments = filteredSegments
    }
}
