import Foundation
import SwiftUI
import UserNotifications
import UIKit

/// Represents the general type of notification being presented to the user.
enum UserNotificationType: Equatable {
    case success
    case warning
    case error
    case info
}

/// Immutable value describing a single user notification.
struct UserNotification: Equatable {
    let title: String
    let body: String
    let type: UserNotificationType
}

/// Centralized user notification service.
/// - Decides whether to display a toast or schedule a system notification based on app state.
/// - Requests notification permissions at initialization.
/// - Handles both interactive foreground toasts and background/lockscreen notifications.
final class UserNotifier {
    
    /// Shared singleton instance for global access.
    static let shared: UserNotifier = {
        let instance = UserNotifier()
        return instance
    }()
    
    /// We manually track the badge count here because iOS 17+ does not provide a direct API to get the current badge count.
    /// This ensures consistency in badge management across app restarts.
    private var currentBadge: Int {
        get { UserDefaults.standard.integer(forKey: "UserNotifier.currentBadge") }
        set { UserDefaults.standard.set(newValue, forKey: "UserNotifier.currentBadge") }
    }
    
    /// Private init ensures only the singleton is used.
    /// Requests system notification authorization on creation.
    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[UserNotifier] Notification authorization error: \(error.localizedDescription)")
            } else {
                print("[UserNotifier] Notification authorization granted: \(granted)")
            }
        }
    }
    
    // MARK: - Public API
    
    /// Presents a notification to the user.
    /// - Parameters:
    ///   - type: The visual/semantic type of notification.
    ///   - title: The main title text.
    ///   - message: The body text.
    ///   - badgeIncrement: Optional integer to increment the app icon badge count by.
    func showNotification(type: UserNotificationType, title: String, message: String, badgeIncrement: Int = 0) {
        let notification = UserNotification(title: title, body: message, type: type)
        
        if badgeIncrement != 0 {
            incrementBadge(by: badgeIncrement)
        }
        
        switch UIApplication.shared.applicationState {
        case .active:
            showToast(notification)
        case .inactive, .background:
            scheduleLocalNotification(notification)
        @unknown default:
            break
        }
    }
    
    /// Specialized helper for movement reminders triggered from significant change events.
    /// Will also increment the badge.
    func showMovementReminder() {
        showNotification(
            type: .info,
            title: "Driving detected",
            message: "Open Simple Miles to automatically record your trip.",
            badgeIncrement: 1
        )
    }
    
    /// Specialized helper for notifying the user of a trip stored for review.
    /// - Parameter tripCount: Number of trips awaiting classification.
    func showTripStored(tripCount: Int) {
        let body = tripCount == 1 ? "You have 1 trip to sort." : "You have \(tripCount) trips to sort."
        showNotification(
            type: .info,
            title: "Trip saved for review",
            message: body
        )
    }
    
    // MARK: - Private Helpers
    
    /// Displays a toast banner in-app for active state.
    private func showToast(_ notification: UserNotification) {
        ToastManager.shared.show(notification)
    }
    
    /// Schedules a system local notification for background/inactive state.
    private func scheduleLocalNotification(_ notification: UserNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        
        content.badge = NSNumber(value: currentBadge)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[UserNotifier] Local notification error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Increments the app icon badge by the specified amount.
    private func incrementBadge(by amount: Int) {
        let newBadge = currentBadge + amount
        currentBadge = newBadge
        UNUserNotificationCenter.current().setBadgeCount(newBadge) { error in
            if let error = error {
                print("[UserNotifier] setBadgeCount error: \(error.localizedDescription)")
            }
        }
    }
    
    /// Clears the app icon badge entirely.
    func clearBadge() {
        currentBadge = 0
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("[UserNotifier] clearBadge setBadgeCount error: \(error.localizedDescription)")
            }
        }
    }
}

// Keep Equatable conformance for completeness, comparing singleton identity.
extension UserNotifier: Equatable {
    static func == (lhs: UserNotifier, rhs: UserNotifier) -> Bool {
        return lhs === rhs
    }
}
