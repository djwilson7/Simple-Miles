//
//  MapContainerViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/19/25.
//

import Foundation
import Combine
import SwiftUI

final class MapContainerViewModel: ObservableObject {
    // MARK: - Published UI Bindings

    @Published var tripStatus: TripRecordingStatus = .idle
    @Published var tripDistance: String = "0.0 miles"
    @Published var tripDuration: String = "0m"
    @Published var remainingPauseTime: TimeInterval = 0
    @Published var sweepProgress: CGFloat = 0

    // MARK: - Action Hooks

    var onRecenter: (() -> Void)?
    var onShare: (() -> Void)?
    var onSettings: (() -> Void)?
    var onSummary: (() -> Void)?
    
    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()
    private let tripService: TripTrackingService

    // MARK: - Computed Bindings

    var tripStatusText: String {
        tripStatus.displayText
    }

    var tripStatusColor: Color {
        tripStatus.color
    }

    var isPaused: Bool {
        tripStatus == .paused
    }

    var pauseCountdownFormatted: String {
        let minutes = Int(remainingPauseTime) / 60
        let seconds = Int(remainingPauseTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }



    // MARK: - Init

    init(tripService: TripTrackingService = .shared) {
        self.tripService = tripService
        bindTripState()
        startSweepProgressLoop()
    }

    // MARK: - State Binding

    private func bindTripState() {
        tripService.$status
            .receive(on: DispatchQueue.main)
            .assign(to: &$tripStatus)

        tripService.recordingState
            .publisherValues.totalDistance
            .receive(on: DispatchQueue.main)
            .map { meters in
                let miles = meters * 0.000621371
                return String(format: "%.1f miles", miles)
            }
            .assign(to: &$tripDistance)

        tripService.recordingState
            .publisherValues.elapsedTime
            .receive(on: DispatchQueue.main)
            .map { time in
                let minutes = Int(time / 60)
                return "\(minutes)m"
            }
            .assign(to: &$tripDuration)

        tripService.recordingState
            .publisherValues.remainingPauseTime
            .receive(on: DispatchQueue.main)
            .assign(to: &$remainingPauseTime)
    }

    // MARK: - Sweep Progress (Looping Clock-Face)

    private func startSweepProgressLoop() {
        var startTime = Date()

        Timer.publish(every: 1.0 / 60.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                guard let self = self, self.isPaused else {
                    startTime = Date()
                    return
                }

                let elapsed = now.timeIntervalSince(startTime)
                self.sweepProgress = CGFloat((elapsed.truncatingRemainder(dividingBy: 60)) / 60)
            }
            .store(in: &cancellables)
    }

    // MARK: - Button Events

    func recenterTapped() {
        onRecenter?()
    }

    func shareTapped() {
        onShare?()
    }

    func settingsTapped() {
        onSettings?()
    }

    func summaryTapped() {
        onSummary?()
    }

}
