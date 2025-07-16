//
//  TripRecordingViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//
import Foundation
import Combine

final class TripRecordingViewModel: ObservableObject {

    @Published private(set) var status: TripRecordingStatus = .idle
    @Published private(set) var distance: Double = 0.0
    @Published private(set) var duration: TimeInterval = 0.0
    @Published private(set) var segmentCount: Int = 0

    private let tracker: TripTrackingService
    private let store: TripSessionStoringProtocol

    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init(
        tracker: TripTrackingService = TripTrackingService.shared,
        store: TripSessionStoringProtocol = TripSessionStore.shared
    ) {
        self.tracker = tracker
        self.store = store
        bind()
    }

    func start() {
        tracker.startRecording()
        status = .recording
        startTimer()
    }

    func stop() {
        tracker.stopRecording()
        status = .idle
        stopTimer()

        if let session = tracker.currentSession {
            store.save(session)
        }
    }

    private func startTimer() {
        stopTimer()
        timer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let start = self?.tracker.currentSession?.startTime else { return }
                self?.duration = Date().timeIntervalSince(start)
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func bind() {
        tracker.$currentSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (session: TripSessionModel?) in
                self?.distance = session?.distance ?? 0
                self?.segmentCount = session?.segments.count ?? 0
            }
            .store(in: &cancellables)
    }
}
