import Foundation
import SwiftUI
import UserNotifications
import UIKit
import Combine

final class UserNotifier {
    
    static let shared: UserNotifier = {
        let instance = UserNotifier()
        return instance
    }()
    
    // Read-only: always reflects the persisted unsorted trip count
    private var unsortedTripCount: Int {
        UserDefaults.standard.integer(forKey: "unsortedTripCount")
    }
    
    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("[UserNotifier] Notification authorization error: \(error.localizedDescription)")
            } else {
                print("[UserNotifier] Notification authorization granted: \(granted)")
            }
        }
        
        // Sync badge immediately on startup
        updateBadgeCount()
        
        // Listen for trip store updates and refresh badge
        TripSegmentStore.shared.tripTotalsUpdated
            .sink { [weak self] in
                self?.updateBadgeCount()
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public API
    
    func showNotification(type: UserNotificationType, title: String, message: String) {
        let notification = UserNotification(title: title, body: message, type: type)
        
        switch UIApplication.shared.applicationState {
        case .active:
            showToast(notification)
        case .inactive, .background:
            scheduleLocalNotification(notification)
        @unknown default:
            break
        }
    }
    
    func showMovementReminder() {
        showNotification(
            type: .info,
            title: "Driving detected",
            message: "Open Simple Miles to automatically record your trip."
        )
    }
    
    func showTripStored() {
        let count = unsortedTripCount
        guard count > 0 else { return }
        
        let body = count == 1 ? "You have 1 trip to sort." : "You have \(count) trips to sort."
        showNotification(
            type: .info,
            title: "Trip saved for review",
            message: body
        )
    }
    
    // MARK: - Private Helpers
    
    private func showToast(_ notification: UserNotification) {
        ToastManager.shared.show(notification)
    }
    
    private func scheduleLocalNotification(_ notification: UserNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        
        let count = unsortedTripCount
        if count > 0 {
            content.badge = NSNumber(value: count)
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("[UserNotifier] Local notification error: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateBadgeCount() {
        let count = unsortedTripCount
        let badgeValue = max(count, 0)
        
        UNUserNotificationCenter.current().setBadgeCount(badgeValue) { error in
            if let error = error {
                print("[UserNotifier] setBadgeCount error: \(error.localizedDescription)")
            }
        }
    }
}

extension UserNotifier: Equatable {
    static func == (lhs: UserNotifier, rhs: UserNotifier) -> Bool {
        lhs === rhs
    }
}
