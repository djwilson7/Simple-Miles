//
//  MapViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class MapViewModel: ObservableObject {
    @Published var pathPoints: [CoordinateModel] = []

    private let sessionStore: TripSessionStoringProtocol
    private var cancellables = Set<AnyCancellable>()

    init(sessionStore: TripSessionStoringProtocol = TripSessionStore()) {
        self.sessionStore = sessionStore
        bindLiveSession()
    }

    /// For showing historical trips (e.g., trip history mode)
    func loadPathPoints(filter type: TripType? = nil) {
        print("[MapViewModel] loadPathPoints triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let sessions = sessionStore.fetchAll()
        let points = sessions
            .filter { type == nil || $0.tripType == type }
            .flatMap { $0.path }

        self.pathPoints = points
    }

    /// For real-time recording UI
    private func bindLiveSession() {
        TripTrackingService.shared.currentSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.pathPoints = session?.path ?? []
            }
            .store(in: &cancellables)
    }
}
