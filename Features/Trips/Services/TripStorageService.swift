//
//  TripStorageService.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/12/25.
//

import Foundation

final class TripStorageService {

    private(set) var trips: [TripModel] = []
    var onTripsUpdated: (() -> Void)?

    init() {
        print("[TripStorageService] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        loadTrips()
    }

    func loadTrips() {
        print("[TripStorageService] loadTrips triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        do {
            self.trips = try TripSerializer.load()
            print("[TripStorageService] loaded \(trips.count) trips") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            onTripsUpdated?()
        } catch {
            print("[TripStorageService] Failed to load trips: \(error.localizedDescription)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            self.trips = []
        }
    }

    func save() {
        print("[TripStorageService] save triggered with \(trips.count) trips") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        do {
            try TripSerializer.save(trips)
        } catch {
            print("[TripStorageService] Failed to save trips: \(error.localizedDescription)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        }
    }

    func add(_ trip: TripModel) {
        print("[TripStorageService] add triggered for tripID: \(trip.id)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard !trips.contains(where: { $0.id == trip.id }) else {
            print("[TripStorageService] trip already exists, skipping") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }
        trips.append(trip)
        save()
        onTripsUpdated?()
    }

    func update(_ updatedTrip: TripModel) {
        print("[TripStorageService] update triggered for tripID: \(updatedTrip.id)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let index = trips.firstIndex(where: { $0.id == updatedTrip.id }) else {
            print("[TripStorageService] no matching trip found to update") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            return
        }
        trips[index] = updatedTrip
        save()
        onTripsUpdated?()
    }

    func delete(id: UUID) {
        print("[TripStorageService] delete triggered for tripID: \(id)") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        trips.removeAll { $0.id == id }
        save()
        onTripsUpdated?()
    }

    func filtered(by type: TripType?) -> [TripModel] {
        print("[TripStorageService] filtered triggered for type: \(String(describing: type))") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        guard let type = type else { return trips }
        return trips.filter { $0.tripType == type }
    }
}
