//
//  TripTimer.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/15/25.
//

import Foundation

final class TripTimer {
    private var stopTimer: Timer?

    func scheduleStop(after seconds: TimeInterval, action: @escaping () -> Void) {
        stopTimer?.invalidate()
        stopTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { _ in
            action()
        }
    }

    func cancelStop() {
        stopTimer?.invalidate()
        stopTimer = nil
    }
}
