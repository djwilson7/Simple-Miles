//
//  CoreDataMapping.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//

import CoreData

// MARK: - CDTripSession ↔ TripSessionModel

extension CDTripSession {
    convenience init(from model: TripSessionModel, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = model.id
        self.startTime = model.startTime
        self.endTime = model.endTime
        self.distance = model.distance
        self.tripType = model.tripType.rawValue
        self.segments = NSSet(array: model.segments.map {
            CDTripSegment(from: $0, session: self, context: context)
        })
    }

    func toModel() -> TripSessionModel {
        TripSessionModel(
            id: self.id ?? UUID(),
            startTime: self.startTime ?? .distantPast,
            endTime: self.endTime,
            distance: self.distance,
            tripType: TripType(rawValue: self.tripType ?? "") ?? .unclassified,
            segments: (segments?.allObjects as? [CDTripSegment])?.map { $0.toModel() } ?? []
        )
    }
}

// MARK: - CDTripSegment ↔ TripSegmentModel

extension CDTripSegment {
    convenience init(from model: TripSegmentModel, session: CDTripSession, context: NSManagedObjectContext) {
        self.init(context: context)
        self.id = model.id
        self.startTime = model.startTime
        self.endTime = model.endTime
        self.avgSpeed = model.speed
        self.distance = model.distance
        self.session = session
        self.coordinates = NSSet(array: [model.startCoordinate, model.endCoordinate].map {
            CDCoordinate(from: $0, segment: self, context: context)
        })
    }

    func toModel() -> TripSegmentModel {
        let coords = (coordinates?.allObjects as? [CDCoordinate]) ?? []
        let sorted = coords.sorted(by:  { (lhs, rhs) in
            (lhs.timestamp ?? Date.distantPast) < (rhs.timestamp ?? Date.distantPast)
        })

        return TripSegmentModel(
            id: self.id ?? UUID(),
            startTime: self.startTime ?? .distantPast,
            endTime: self.endTime ?? .distantFuture,
            startCoordinate: sorted.first?.toModel() ?? .init(latitude: 0, longitude: 0),
            endCoordinate: sorted.last?.toModel() ?? .init(latitude: 0, longitude: 0),
            distance: self.distance
        )
    }
}

// MARK: - CDCoordinate ↔ CoordinateModel

extension CDCoordinate {
    convenience init(from model: CoordinateModel, segment: CDTripSegment, context: NSManagedObjectContext) {
        self.init(context: context)
        self.latitude = model.latitude
        self.longitude = model.longitude
        self.timestamp = Date()
        self.segment = segment
    }

    func toModel() -> CoordinateModel {
        CoordinateModel(
            latitude: latitude,
            longitude: longitude
        )
    }
}
