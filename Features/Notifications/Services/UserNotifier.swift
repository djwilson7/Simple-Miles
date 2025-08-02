import Foundation
import SwiftUI
import UserNotifications

enum UserNotificationType: Equatable {
    case success
    case warning
    case error
}

struct UserNotification: Equatable {
    let title: String
    let body: String
    let type: UserNotificationType
}

final class UserNotifier {
    static let shared: UserNotifier = {
        let instance = UserNotifier()
        return instance
    }()

    private init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            } else {
                print("Notification authorization granted: \(granted)")
            }
        }
    }

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

    private func showToast(_ notification: UserNotification) {
        ToastManager.shared.show(notification)
    }

    private func scheduleLocalNotification(_ notification: UserNotification) {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
}

extension UserNotifier: Equatable {
    static func == (lhs: UserNotifier, rhs: UserNotifier) -> Bool {
        return lhs === rhs
    }
}
