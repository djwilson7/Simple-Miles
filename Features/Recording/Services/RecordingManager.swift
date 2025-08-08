import Foundation
import Combine
import CoreLocation
import SwiftUI

/// Singleton responsible for managing trip recording lifecycle, handling travel state transitions,
/// and aggregating trip data such as distance, duration, and segments.
/// 
/// It listens to location and travel state updates, manages live and committed trip segments,
/// and provides interpolated paths for UI updates.  
/// 
/// Usage:
/// 1. Access the shared instance via `RecordingManager.shared`.
/// 2. Call `initialize()` once to bind publishers and load existing segments.
/// 3. Observe published properties to reflect recording status and trip data.
/// 4. TravelState changes (traveling, paused, idle) drive the recording lifecycle internally.
final class RecordingManager {
    
    // MARK: Singleton & Initialization
    /// Singleton instance for centralized recording management.
    /// 
    /// Call `initialize()` once after accessing this instance to set up publishers and load saved data.
    
    /// Shared singleton instance of `RecordingManager`.
    static let shared = RecordingManager()
    
    /// Private initializer to enforce singleton usage.
    private init() {}
    
    /// Sets up Combine publishers, binds state and location updates,
    /// and loads all previously finalized trip segments from persistent storage.
    ///
    /// This method must be called once after accessing `RecordingManager.shared`.
    func initialize() {
        travelStatePublisher = TravelStateManager.shared.$state
        currentLocationPublisher = LocationManager.shared.$currentLocation
        lastLocationPublisher = LocationManager.shared.$lastLocation
        
        bindPublishers()
        loadAllFinalizedSegments()
    }
    
    
    // MARK: Dependencies
    /// External dependencies and publishers for location, heading, and travel state updates.
    
    /// Publisher providing compass heading updates from LocationManager.
    private let compassHeadingPublisher = LocationManager.shared.$compassHeading
    /// Publisher providing current travel state updates (e.g. traveling, paused, idle).
    private var travelStatePublisher: Published<TravelState>.Publisher!
    /// Publisher providing the current GPS location.
    private var currentLocationPublisher: Published<CLLocation?>.Publisher!
    /// Publisher providing the previous GPS location.
    private var lastLocationPublisher: Published<CLLocation?>.Publisher!
    /// Manages persistence of trip segments on disk or database.
    private let tripSegmentStore = TripSegmentStore()
    /// Shared application settings, including minimum trip distance threshold.
    private let settings = AppSettings.shared
    
    
    // MARK: Published Properties
    /// Publicly observable properties representing trip recording state and aggregated data.
    
    /// Total distance (meters) from all committed (finalized) trip segments.
    @Published var tripDistanceCommitted: CLLocationDistance = 0
    /// Distance (meters) of the current live trip segment during recording.
    @Published var tripDistanceLive: CLLocationDistance = 0
    /// Total duration (seconds) from all committed (finalized) trip segments.
    @Published var tripDurationCommitted: TimeInterval = 0
    /// Duration (seconds) of the current live trip segment during recording.
    @Published var tripDurationLive: TimeInterval = 0
    /// Flag indicating whether recording is currently active (traveling or paused).
    @Published var isRecording: Bool = false
    /// Coordinates aggregated from all finalized trip segments, representing the committed path.
    @Published var commitedPath: [CLLocationCoordinate2D] = []
    /// Coordinates of the currently recording trip segment, representing the live path.
    @Published var nonCommitedPath: [CLLocationCoordinate2D] = []
    /// All loaded trip segments, both committed and possibly unclassified.
    @Published var allSegments: [TripSegment] = []
    
    
    // MARK: Internal State
    /// Internal state variables to track compass heading, timing, location, and current segments.
    
    /// Current compass heading (degrees) from LocationManager.
    private var compassHeading: CLLocationDirection?
    /// Buffer to accumulate compass headings received while the recording is paused.
    private var pausedHeadingBuffer: [CLLocationDirection] = []
    
    /// Timestamp when the current trip segment started.
    private var tripStartTime: Date?
    
    /// Set of cancellables managing subscriptions to Combine publishers.
    private var cancellables = Set<AnyCancellable>()
    /// Current GPS location received from LocationManager.
    private var currentLocation: CLLocation?
    /// Last known GPS location received from LocationManager.
    private var lastLocation: CLLocation?
    /// Tracks the previous travel state to detect transitions.
    private var previousState: TravelState?
    /// Timer subscription updating the live trip duration every second.
    private var durationTimer: AnyCancellable?
    
    /// TripSegment currently being recorded live.
    private var liveSegment: TripSegment?
    /// Most recent finalized or paused trip segment.
    private var previousSegment: TripSegment?
    /// TripSegment representing the paused state, capturing the pause duration and path.
    private var pausedSegment: TripSegment?
    /// Location anchor point where the trip was paused.
    private var pauseAnchor: CLLocation?
    
    
    // MARK: Public API
    /// Interpolates intermediate coordinates between two geographic points.
    ///
    /// This is useful for smoothing or filling gaps in recorded paths.
    ///
    /// - Parameters:
    ///   - from: Starting coordinate.
    ///   - to: Ending coordinate.
    ///   - steps: Number of interpolation steps between the two points.
    /// - Returns: Array of interpolated coordinates starting after `from` and ending at `to`.
    func interpolatePoints(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, steps: Int) -> [CLLocationCoordinate2D] {
        guard steps > 1 else { return [to] }
        let latStep = (to.latitude - from.latitude) / Double(steps)
        let lonStep = (to.longitude - from.longitude) / Double(steps)
        return (1..<steps).map { i in
            CLLocationCoordinate2D(latitude: from.latitude + latStep * Double(i),
                                   longitude: from.longitude + lonStep * Double(i))
        } + [to]
    }
    
    
    // MARK: Lifecycle Management
    /// Methods handling setup and updating of internal state in response to external publisher events.
    
    /// Subscribes to required publishers to update internal state reactively based on travel state,
    /// location, last location, and compass heading changes.
    private func bindPublishers() {
        travelStatePublisher
            .sink { [weak self] state in self?.handleTravelStateUpdate(state) }
            .store(in: &cancellables)
        
        currentLocationPublisher
            .sink { [weak self] location in
                guard let self = self else { return }
                self.currentLocation = location
                guard self.isRecording,
                      let location = location else { return }
                
                self.liveSegment?.append(location: location)
                self.nonCommitedPath = self.liveSegment?.pathCoordinates ?? []
                self.tripDistanceLive = self.liveSegment?.distance ?? 0
            }
            .store(in: &cancellables)
        
        lastLocationPublisher
            .sink { [weak self] location in self?.lastLocation = location }
            .store(in: &cancellables)
        
        compassHeadingPublisher
            .sink { [weak self] heading in
                guard let self = self else { return }
                self.compassHeading = heading
                // Buffer compass headings while paused for merging logic
                if self.previousState == .paused {
                    self.pausedHeadingBuffer.append(heading)
                }
            }
            .store(in: &cancellables)
    }
    
    /// Loads all previously finalized trip segments from persistent store into memory.
    private func loadAllFinalizedSegments() {
        allSegments = tripSegmentStore.loadAllUnclassified()
    }
    
    /// Resets internal state and published properties to initial values,
    /// clearing any ongoing or paused trip data.
    private func reset() {
        commitedPath = []
        nonCommitedPath = []
        tripStartTime = nil
        tripDistanceLive = 0
        tripDistanceCommitted = 0
        tripDurationLive = 0
        tripDurationCommitted = 0
        stopDurationTimer()
        liveSegment = nil
        previousSegment = nil
        pausedSegment = nil
        pauseAnchor = nil
    }
    
    /// Starts a timer updating the live trip duration every second,
    /// based on the current trip start time.
    private func startDurationTimer() {
        stopDurationTimer()
        tripStartTime = Date()
        durationTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self,
                      let start = self.tripStartTime else { return }
                self.tripDurationLive = Date().timeIntervalSince(start)
            }
    }
    
    /// Stops the current duration timer, if active.
    private func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
    }
    
    
    // MARK: State Transition Logic
    /// Internal methods managing state transitions and trip segment lifecycle.
    
    /// Handles travel state updates from the `TravelStateManager`, managing lifecycle transitions
    /// between traveling, paused, and idle states.
    ///
    /// This method orchestrates starting, pausing, resuming, and finalizing trip recording accordingly.
    ///
    /// - Parameter state: The new travel state.
    private func handleTravelStateUpdate(_ state: TravelState) {
        switch state {
        case .traveling:
            transitionToTraveling()
        case .paused:
            transitionToPaused()
        case .idle:
            transitionToIdle()
        }
        previousState = state
        isRecording = (state == .traveling || state == .paused)
    }
    
    /// Called when travel state changes to `.traveling`.
    /// 
    /// Starts or resumes recording a live trip segment. If resuming from paused,
    /// merges paused segment with previous segment if appropriate. Writes segments to persistence.
    private func transitionToTraveling() {
        if previousState == .paused {
            transitionFromPausedToTraveling()
        }
        
        startDurationTimer()
        
        liveSegment = TripSegment(startTimestamp: Date())
        if currentLocation != nil {
            liveSegment!.append(location: currentLocation!)
        }
        
        if previousSegment != nil {
            tripSegmentStore.write(previousSegment!)
        }
        
        if liveSegment != nil {
            tripSegmentStore.write(liveSegment!)
        }
    }
    
    /// Handles the special case transition from `.paused` to `.traveling`.
    ///
    /// - Merges the paused segment into the previous segment if merging conditions based on heading are met.
    /// - Otherwise, persists the previous segment if it meets minimum distance requirements.
    /// - Resets paused-related state and clears heading buffers.
    private func transitionFromPausedToTraveling() {
        pausedSegment?.duration = tripDurationLive
        
        if PauseSegmentClassifier.shouldMerge(pausedSegment!, anchorHeading: pauseAnchor!.course, headingBuffer: pausedHeadingBuffer) {
            previousSegment!.merge(with: pausedSegment!)
            tripSegmentStore.write(previousSegment!)
            commitedPath = previousSegment!.pathCoordinates
        } else {
            let minimumMeters = settings.minimumTripDistance * 1609.34
            if previousSegment!.distance >= minimumMeters {
                previousSegment = persistAndDelete(previousSegment!)
            }
            commitedPath = []
        }
        nonCommitedPath = []
        tripDistanceCommitted = previousSegment?.distance ?? 0
        tripDurationCommitted = previousSegment?.duration ?? 0
        pausedHeadingBuffer.removeAll()
        pausedSegment = nil
        pauseAnchor = nil
    }
   
    /// Called when travel state changes to `.paused`.
    ///
    /// Finalizes the live segment, merges it into the previous segment or assigns it as previous,
    /// persists changes, and starts a new segment representing the paused state.
    private func transitionToPaused() {
        guard previousState == .traveling else { return }
        
        liveSegment?.duration = tripDurationLive
        liveSegment?.distance = tripDistanceLive
        startDurationTimer()
        
        if previousSegment != nil {
            previousSegment?.merge(with: liveSegment!)
        } else {
            previousSegment = liveSegment
        }
        commitedPath = previousSegment!.pathCoordinates
        tripSegmentStore.write(previousSegment!)
        nonCommitedPath = []
        
        tripDurationCommitted = previousSegment!.duration
        tripDistanceCommitted = previousSegment!.distance
        tripDistanceLive = 0
        liveSegment = nil
        
        pauseAnchor = currentLocation
        pausedSegment = TripSegment(startTimestamp: Date())
        if let current = currentLocation {
            pausedSegment?.append(location: current)
        }
    }
    
    /// Called when travel state changes to `.idle`.
    ///
    /// Finalizes any ongoing segment if it meets minimum distance requirements,
    /// appends the last location if needed, reloads finalized segments,
    /// and resets all internal state to prepare for a new trip.
    private func transitionToIdle() {
        guard previousState == .paused else { return }
        
        if let location = currentLocation {
            let lastCoordinate = previousSegment?.pathCoordinates.last
            let currentCoordinate = location.coordinate
            if lastCoordinate == nil ||
                lastCoordinate!.latitude != currentCoordinate.latitude ||
                lastCoordinate!.longitude != currentCoordinate.longitude
            {
                previousSegment?.append(location: location)
            }
        }
        
        let minimumMeters = settings.minimumTripDistance * 1609.34
        if previousSegment!.distance >= minimumMeters {
            previousSegment = persistAndDelete(previousSegment!)
            loadAllFinalizedSegments()
        }
        reset()
    }

    // MARK: Segment Utilities
    /// Persists the given segment with finalization, then deletes it from the store.
    ///
    /// Returns nil to indicate the segment is no longer valid to keep in memory.
    ///
    /// - Parameter segment: The trip segment to finalize and delete.
    /// - Returns: Always returns nil.
    private func persistAndDelete(_ segment: TripSegment) -> TripSegment? {
        finalizeAndWrite(segment)
        tripSegmentStore.delete(segment)
        return nil
    }
    
    /// Finalizes a trip segment by setting its end timestamp and writes it to persistent storage.
    ///
    /// - Parameter segment: The trip segment to finalize and write.
    private func finalizeAndWrite(_ segment: TripSegment?) {
        guard var segment = segment else { return }
        segment.finalize(at: Date())
        tripSegmentStore.write(segment)
    }
    
}
