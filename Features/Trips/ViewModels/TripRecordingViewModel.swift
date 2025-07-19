//  TripRecordingViewModel.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

// TripRecordingViewModel.swift
// SimpleMiles

import Foundation
import Combine

@MainActor
final class TripRecordingViewModel: ObservableObject {
    enum Status {
        case idle
        case recording
    }

    @Published var status: Status = .idle
    @Published var pathPointCount: Int = 0
    @Published var distance: Double = 0
    @Published var duration: TimeInterval = 0

    private var timerCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    @Published private(set) var currentSession: TripSessionModel?

    private let tracker: any TripTrackingServiceProtocol
    private let store: any TripPersistenceManagingProtocol

    init(
        tracker: some TripTrackingServiceProtocol,
        store: some TripPersistenceManagingProtocol
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

        if let session = currentSession {
            store.save(session)
        }
    }

    private func bind() {
        tracker.currentSessionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.currentSession = session
                self?.distance = session?.distance ?? 0
                self?.pathPointCount = session?.path.count ?? 0
            }
            .store(in: &cancellables)
    }

    private func startTimer() {
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
