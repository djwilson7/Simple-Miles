//
//  DeveloperPanelViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

final class DeveloperPanelViewModel: ObservableObject {
    @Published var isTracking: Bool = false
    @Published var currentDistance: Double = 0
    @Published var currentSegmentCount: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var exportLauncher = ExportLauncher()
    @Published var savedTripCount: Int = 0
    @Published var remainingPauseTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    @Published var resumeSpeedThreshold: Double = 2.5
    @Published var resumeDistanceThreshold: Double = 50.0

    private let tripService: TripTrackingService
    private let recordingState: TripRecordingState
    private let exportViewModel: TripExportViewModel
    private var cancellables = Set<AnyCancellable>()

    init(
        tripService: TripTrackingService = .shared,
        exportViewModel: TripExportViewModel = TripExportViewModel()
    ) {
        self.tripService = tripService
        self.recordingState = tripService.recordingState
        self.exportViewModel = exportViewModel
        bindLiveTripState()
        tripService.onTripSaved = { [weak self] in
            self?.refreshTripCount()
        }

        $resumeSpeedThreshold
            .combineLatest($resumeDistanceThreshold)
            .sink { [weak self] speed, distance in
                self?.tripService.updateAnalyzerThresholds(speed: speed, distance: distance)
            }
            .store(in: &cancellables)
    }

    private func bindLiveTripState() {
        recordingState.$isRecording
            .assign(to: &$isTracking)

        recordingState.$totalDistance
            .assign(to: &$currentDistance)

        recordingState.$segmentCount
            .assign(to: &$currentSegmentCount)

        recordingState.$elapsedTime
            .assign(to: &$elapsedTime)
        
        recordingState.$remainingPauseTime
            .assign(to: &$remainingPauseTime)

        recordingState.$pauseExpiresAt
            .map { $0 != nil }
            .assign(to: &$isPaused)
    }

    func toggleTracking() {
        print("[DeveloperPanelViewModel] toggleTracking triggered")
        isTracking ? tripService.stopRecording() : tripService.startRecording()
    }

    func exportAllTripsAsCSV() {
        print("[DeveloperPanelViewModel] exportAllTripsAsCSV triggered")
        if let url = exportViewModel.generateCSVExport() {
            exportLauncher.launch(for: url)
            savedTripCount = 0 //reset count after export trigger
        }
    }

    func exportAllTripsAsJSON() {
        print("[DeveloperPanelViewModel] exportAllTripsAsJSON triggered")
        if let url = exportViewModel.generateJSONBackup() {
            exportLauncher.launch(for: url)
            savedTripCount = 0 //reset count after export trigger
        }
    }
    
    func refreshTripCount() {
        savedTripCount = exportViewModel.store.fetchAll().count
    }
    
    func resetPauseTimer() {
        print("[DeveloperPanelViewModel] resetPauseTimer triggered")
        recordingState.resetPauseCountdown()
    }

    func forceEndTrip() {
        print("[DeveloperPanelViewModel] forceEndTrip triggered")
        tripService.stopRecording()
        tripService.recordingState.reset()
        isPaused = false
        tripService.startPassiveMonitoring()
    }

    func clearAllTrips() {
        print("[DeveloperPanelViewModel] clearAllTrips triggered")
        tripService.clearAllTrips()
    }
}
