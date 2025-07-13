//
//  TripStorageService.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation

final class TripStorageService {
    
    // MARK: - Properties
    
    private(set) var trips: [TripModel] = []
    
    // Optional closure to notify observers (e.g., view models)
    var onTripsUpdated: (() -> Void)?

    // MARK: - Initialization
    
    init() {
        loadTrips()
    }
    
    // MARK: - Core Methods
    
    func loadTrips() {
        do {
            self.trips = try TripSerializer.load()
            onTripsUpdated?()
        } catch {
            print("Failed to load trips: \(error.localizedDescription)")
            self.trips = []
        }
    }
    
    func save() {
        do {
            try TripSerializer.save(trips)
        } catch {
            print("Failed to save trips: \(error.localizedDescription)")
        }
    }
    
    func add(_ trip: TripModel) {
        guard !trips.contains(where: { $0.id == trip.id }) else {
            return // Skip duplicates
        }
        trips.append(trip)
        save()
        onTripsUpdated?()
    }
    
    func update(_ updatedTrip: TripModel) {
        guard let index = trips.firstIndex(where: { $0.id == updatedTrip.id }) else { return }
        trips[index] = updatedTrip
        save()
        onTripsUpdated?()
    }
    
    func delete(id: UUID) {
        trips.removeAll { $0.id == id }
        save()
        onTripsUpdated?()
    }
    
    func filtered(by type: TripType?) -> [TripModel] {
        guard let type = type else { return trips }
        return trips.filter { $0.tripType == type }
    }
}
