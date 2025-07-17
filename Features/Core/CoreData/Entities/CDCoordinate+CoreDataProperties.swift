//
//  CDCoordinate+CoreDataProperties.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/17/25.
//
//

import Foundation
import CoreData


extension CDCoordinate {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDCoordinate> {
        return NSFetchRequest<CDCoordinate>(entityName: "CDCoordinate")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var timestamp: Date?
    @NSManaged public var segment: CDTripSegment?
    @NSManaged public var trip: CDTripSession?

}

extension CDCoordinate : Identifiable {

}
