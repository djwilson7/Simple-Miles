//
//  UserNotification.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/8/25.
//
import Foundation

/// Immutable value describing a single user notification.
struct UserNotification: Equatable {
    let title: String
    let body: String
    let type: UserNotificationType
}
