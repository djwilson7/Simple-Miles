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
    @Published var loggedTripCoords: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var savedTripCount: Int = 0
    @Published var remainingPauseTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    @Published var resumeSpeedThreshold: Double = 2.5
    @Published var resumeDistanceThreshold: Double = 50.0
    @Published var exportLauncher: ExportLaunchingProtocol

    private let tripService: TripTrackingServiceProtocol
    private let recordingState: any TripRecordingStateProtocol
    private let exportViewModel: TripExportViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        tripService: TripTrackingServiceProtocol = TripTrackingService.shared,
        exportViewModel: TripExportViewModelProtocol = TripExportViewModel(),
        exportLauncher: ExportLaunchingProtocol = ExportLauncher()
    ) {
        print("[DeveloperPanelViewModel] init triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        self.tripService = tripService
        self.recordingState = tripService.recordingState
        self.exportViewModel = exportViewModel
        self.exportLauncher = exportLauncher
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
        let publishers = recordingState.publisherValues

        publishers.isRecording
            .assign(to: &$isTracking)

        publishers.totalDistance
            .assign(to: &$currentDistance)

        publishers.loggedTripCoords
            .assign(to: &$loggedTripCoords)

        publishers.elapsedTime
            .assign(to: &$elapsedTime)

        publishers.remainingPauseTime
            .assign(to: &$remainingPauseTime)

        publishers.isPaused
            .assign(to: &$isPaused)
    }

    func toggleTracking() {
        isTracking ? tripService.stopRecording() : tripService.startRecording()
    }

    func exportAllTripsAsCSV() {
        if let url = exportViewModel.generateCSVExport() {
            exportLauncher.launch(for: url)
            savedTripCount = 0
        }
    }

    func exportAllTripsAsJSON() {
        if let url = exportViewModel.generateJSONBackup() {
            exportLauncher.launch(for: url)
            savedTripCount = 0
        }
    }

    func refreshTripCount() {
        savedTripCount = exportViewModel.store.fetchAll().count
    }

    func resetPauseTimer() {
        recordingState.resetPauseCountdown(duration: 600)
    }

    func forceEndTrip() {
        tripService.stopRecording()
        tripService.recordingState.reset()
        isPaused = false
        tripService.startPassiveMonitoring()
    }

    func clearAllTrips() {
        tripService.clearAllTrips()
    }
}
