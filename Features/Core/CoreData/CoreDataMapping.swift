import CoreData

extension CDTripSession {
    convenience init(from model: TripSessionModel, context: NSManagedObjectContext) {
        print("[CoreDataMapping] CDTripSession init from model triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.init(context: context)
        self.id = model.id
        self.startTime = model.startTime
        self.endTime = model.endTime
        self.distance = model.distance
        self.tripType = model.tripType.rawValue
        self.path = NSSet(array: model.path.map {
            CDCoordinate(from: $0, trip: self, context: context)
        })
    }

    func toModel() -> TripSessionModel {
        print("[CoreDataMapping] CDTripSession toModel triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        let coords = (path?.allObjects as? [CDCoordinate]) ?? []
        let sorted = coords.sorted(by: { (lhs, rhs) in
            (lhs.timestamp ?? Date.distantPast) < (rhs.timestamp ?? Date.distantPast)
        })

        return TripSessionModel(
            id: self.id ?? UUID(),
            startTime: self.startTime ?? .distantPast,
            endTime: self.endTime,
            distance: self.distance,
            tripType: TripType(rawValue: self.tripType ?? "") ?? .unclassified,
            path: sorted.map { $0.toModel() }
        )
    }
}

extension CDCoordinate {
    convenience init(from model: CoordinateModel, trip: CDTripSession, context: NSManagedObjectContext) {
        print("[CoreDataMapping] CDCoordinate init from model triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.init(context: context)
        self.latitude = model.latitude
        self.longitude = model.longitude
        self.timestamp = Date()
        self.trip = trip
    }

    func toModel() -> CoordinateModel {
        print("[CoreDataMapping] CDCoordinate toModel triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        return CoordinateModel(
            latitude: latitude,
            longitude: longitude
        )
    }
}
