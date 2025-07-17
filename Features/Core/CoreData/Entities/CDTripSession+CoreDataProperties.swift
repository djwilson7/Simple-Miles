//
//  CDTripSession+CoreDataProperties.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/17/25.
//
//

import Foundation
import CoreData


extension CDTripSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTripSession> {
        return NSFetchRequest<CDTripSession>(entityName: "CDTripSession")
    }

    @NSManaged public var distance: Double
    @NSManaged public var endTime: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var startTime: Date?
    @NSManaged public var tripType: String?
    @NSManaged public var segments: NSSet?
    @NSManaged public var path: NSSet?

}

// MARK: Generated accessors for segments
extension CDTripSession {

    @objc(addSegmentsObject:)
    @NSManaged public func addToSegments(_ value: CDTripSegment)

    @objc(removeSegmentsObject:)
    @NSManaged public func removeFromSegments(_ value: CDTripSegment)

    @objc(addSegments:)
    @NSManaged public func addToSegments(_ values: NSSet)

    @objc(removeSegments:)
    @NSManaged public func removeFromSegments(_ values: NSSet)

}

// MARK: Generated accessors for path
extension CDTripSession {

    @objc(addPathObject:)
    @NSManaged public func addToPath(_ value: CDCoordinate)

    @objc(removePathObject:)
    @NSManaged public func removeFromPath(_ value: CDCoordinate)

    @objc(addPath:)
    @NSManaged public func addToPath(_ values: NSSet)

    @objc(removePath:)
    @NSManaged public func removeFromPath(_ values: NSSet)

}

extension CDTripSession : Identifiable {

}
