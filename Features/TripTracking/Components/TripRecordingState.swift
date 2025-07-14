//
//  TripRecordingState.swift
//  Simple Miles
//
//  Created by Invictus Maneo on 7/13/25.
//

import Foundation

final class TripRecordingState: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var session: TripSessionModel?
    @Published var elapsedTime: TimeInterval = 0
    @Published var segmentCount: Int = 0
    @Published var totalDistance: Double = 0.0

    private var timer: Timer?
    
    #if DEBUG
    var debugTimer: Timer? {
        return timer
    }
    #endif
    
    func update(with session: TripSessionModel?) {
        self.session = session
        self.segmentCount = session?.segments.count ?? 0
        self.totalDistance = session?.distance ?? 0.0

        if let start = session?.startTime, let end = session?.endTime {
            self.elapsedTime = end.timeIntervalSince(start)
        } else if let start = session?.startTime {
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    func reset() {
        self.isRecording = false
        self.session = nil
        self.elapsedTime = 0
        self.segmentCount = 0
        self.totalDistance = 0
        self.timer?.invalidate()
        self.timer = nil
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let start = self.session?.startTime else { return }
            self.elapsedTime = Date().timeIntervalSince(start)
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    

}


