import Foundation
import Combine

final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var currentToast: UserNotification?

    private var toastTimer: Timer?

    func show(_ notification: UserNotification, duration: TimeInterval = 2.5) {
        currentToast = notification
        toastTimer?.invalidate()
        toastTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.currentToast = nil
        }
    }
}
