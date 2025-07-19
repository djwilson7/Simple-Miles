import Foundation
import UserNotifications
import Combine

final class TripStatusNotifier {
    private var cancellables = Set<AnyCancellable>()

    init() {
        requestPermissions()
        bindNotifications()
    }

    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if !granted {
                print("[TripStatusNotifier] Notification permission not granted.")
            }
        }
    }

    private func bindNotifications() {
        NotificationCenter.default.publisher(for: .tripDidStart)
            .sink { _ in self.send("Trip Started", "Your trip is now being recorded.") }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .tripDidPause)
            .sink { _ in self.send("Trip Paused", "Tracking has paused due to inactivity.") }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .tripDidResume)
            .sink { _ in self.send("Trip Resumed", "Movement detected. Resuming trip.") }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .tripDidEnd)
            .sink { _ in self.send("Trip Ended", "Trip session ended. Passive monitoring enabled.") }
            .store(in: &cancellables)
    }

    private func send(_ title: String, _ message: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
