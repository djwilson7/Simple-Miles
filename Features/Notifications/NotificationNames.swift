//
//  NotificationNames.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/17/25.
//

import Foundation

extension Notification.Name {
    static let didClearTripData = Notification.Name("didClearTripData")
    static let tripDidStart = Notification.Name("tripDidStart")
    static let tripDidPause = Notification.Name("tripDidPause")
    static let tripDidResume = Notification.Name("tripDidResume")
    static let tripDidEnd = Notification.Name("tripDidEnd")
}

