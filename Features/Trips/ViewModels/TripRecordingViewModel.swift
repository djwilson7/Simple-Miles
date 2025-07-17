//
//  TripRecordingViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import Foundation
import Combine

@MainActor
final class TripRecordingViewModel: ObservableObject {
    enum Status {
        case idle
        case recording
    }

    @Published var status: Status = .idle
    @Published var segmentCount: Int = 0
    @Published var distance: Double = 0
    @Published var duration: TimeInterval = 0

    private var timer: Timer?
    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var currentSession: TripSessionModel?

    private let tracker: any TripTrackingServiceProtocol
    private let store: TripPersistenceManager

    init(
        tracker: some TripTrackingServiceProtocol,
        store: some TripPersistenceManager
    ) {
        self.tracker = tracker
        self.store = store
        bind()
    }

    func start() {
        print("[TripRecordingViewModel] start triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        tracker.startRecording()
        status = .recording
        startTimer()
    }

    func stop() {
        print("[TripRecordingViewModel] stop triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        tracker.stopRecording()
        status = .idle
        stopTimer()

        if let session = currentSession {
            print("[TripRecordingViewModel] saving session on stop") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
            store.save(session)
        }
    }

    private func bind() {
        tracker.currentSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                print("[TripRecordingViewModel] session updated")
                self?.currentSession = session
                self?.distance = session?.distance ?? 0
                self?.segmentCount = session?.path.count ?? 0
            }
            .store(in: &cancellables)
    }

    private func startTimer() {
        print("[TripRecordingViewModel] startTimer triggered") //DEBUG PRINT STATEMENT TO BE REMOVED FOR PRODUCTION.
        stopTimer()

        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let start = self?.currentSession?.startTime else { return }
                self?.duration = Date().timeIntervalSince(start)
            }
    }

    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
}
