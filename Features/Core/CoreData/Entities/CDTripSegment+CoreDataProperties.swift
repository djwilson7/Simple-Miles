//
//  CDTripSegment+CoreDataProperties.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/13/25.
//
//

import Foundation
import CoreData


extension CDTripSegment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTripSegment> {
        return NSFetchRequest<CDTripSegment>(entityName: "CDTripSegment")
    }

    @NSManaged public var avgSpeed: Double
    @NSManaged public var endTime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var tripType: Int16
    @NSManaged public var distance: Double
    @NSManaged public var coordinates: NSSet?
    @NSManaged public var session: CDTripSession?

}

// MARK: Generated accessors for coordinates
extension CDTripSegment {

    @objc(addCoordinatesObject:)
    @NSManaged public func addToCoordinates(_ value: CDCoordinate)

    @objc(removeCoordinatesObject:)
    @NSManaged public func removeFromCoordinates(_ value: CDCoordinate)

    @objc(addCoordinates:)
    @NSManaged public func addToCoordinates(_ values: NSSet)

    @objc(removeCoordinates:)
    @NSManaged public func removeFromCoordinates(_ values: NSSet)

}

extension CDTripSegment : Identifiable {

}
