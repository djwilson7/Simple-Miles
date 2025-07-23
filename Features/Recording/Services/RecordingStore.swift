import Foundation
import CoreLocation

final class RecordingStore {
    static let shared = RecordingStore()
    
    private let tempTripFilename = "trip_in_progress.json"
    private var tempTripURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(tempTripFilename)
    }
    
    private var isRecording = false
    private var currentRecording: [CLLocation] = []
    private var tripOriginCoordinate: CLLocationCoordinate2D?
    private var tripOriginStartTime: Date?
    private var lastDistanceCoordinate: CLLocationCoordinate2D?
    private var tripDistance: CLLocationDistance = 0
    private var tripDuration: TimeInterval = 0
    
    private init() {}
    
    static func updateLivePath(_ location: CLLocation) {
        let store = RecordingStore.shared
        if !store.isRecording {
            store.isRecording = true
            store.currentRecording = []
            store.tripOriginCoordinate = location.coordinate
            store.tripOriginStartTime = location.timestamp
            store.tripDistance = 0
            store.tripDuration = 0
            store.lastDistanceCoordinate = nil
        }
        if let lastCoordinate = store.lastDistanceCoordinate {
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            let distance = lastLocation.distance(from: location)
            store.tripDistance += distance
        }
        store.lastDistanceCoordinate = location.coordinate
        if let startTime = store.tripOriginStartTime {
            store.tripDuration = location.timestamp.timeIntervalSince(startTime)
        }
        store.currentRecording.append(location)
        store.persistCurrentRecording()
    }
    
    static func finalizeLivePath(_ location: CLLocation) {
        let store = RecordingStore.shared
        guard store.isRecording else { return }
        store.currentRecording.append(location)
        
        // Save the completed trip to disk
        let tripData = store.currentRecording.map { [$0.coordinate.latitude, $0.coordinate.longitude, $0.timestamp.timeIntervalSince1970] }
        do {
            let data = try JSONSerialization.data(withJSONObject: tripData, options: [])
            let filename = "trip_\(Date().timeIntervalSince1970).json"
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
            try data.write(to: url)
            print("Trip saved to: \(url)")
            try? FileManager.default.removeItem(at: store.tempTripURL)
        } catch {
            print("Failed to save trip: \(error)")
        }
        
        store.isRecording = false
        store.currentRecording = []
        store.tripOriginCoordinate = nil
        store.tripOriginStartTime = nil
        store.tripDistance = 0
        store.tripDuration = 0
        store.lastDistanceCoordinate = nil
    }
    
    private func persistCurrentRecording() {
        let tripData = currentRecording.map { [$0.coordinate.latitude, $0.coordinate.longitude, $0.timestamp.timeIntervalSince1970] }
        do {
            let data = try JSONSerialization.data(withJSONObject: tripData, options: [])
            try data.write(to: tempTripURL)
        } catch {
            print("Failed to persist current trip: \(error)")
        }
    }
    
    static func finalizeIncompleteTripIfNeeded() {
        let store = RecordingStore.shared
        let url = store.tempTripURL
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data, options: []),
              let array = json as? [[Double]] else { return }
        
        let locations: [CLLocation] = array.compactMap {
            guard $0.count == 3 else { return nil }
            return CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]),
                altitude: 0,
                horizontalAccuracy: kCLLocationAccuracyBest,
                verticalAccuracy: kCLLocationAccuracyBest,
                timestamp: Date(timeIntervalSince1970: $0[2])
            )
        }
        
        if let lastLocation = locations.last {
            finalizeLivePath(lastLocation)
        }
    }
    
    static func loadAllStoredTrips() -> [[CLLocation]] {
        let store = RecordingStore.shared
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let tripFiles = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        let completedTripFiles = tripFiles.filter { $0.lastPathComponent.hasPrefix("trip_") && $0.pathExtension == "json" && $0.lastPathComponent != store.tempTripFilename }
        
        var allTrips: [[CLLocation]] = []
        
        for fileURL in completedTripFiles {
            guard let data = try? Data(contentsOf: fileURL),
                  let json = try? JSONSerialization.jsonObject(with: data, options: []),
                  let array = json as? [[Double]] else { continue }
            
            let locations: [CLLocation] = array.compactMap {
                guard $0.count == 3 else { return nil }
                return CLLocation(
                    coordinate: CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]),
                    altitude: 0,
                    horizontalAccuracy: kCLLocationAccuracyBest,
                    verticalAccuracy: kCLLocationAccuracyBest,
                    timestamp: Date(timeIntervalSince1970: $0[2])
                )
            }
            
            allTrips.append(locations)
        }
        
        return allTrips
    }
    
    static var tripOriginCoordinate: CLLocationCoordinate2D? {
        shared.tripOriginCoordinate
    }

    static var tripOriginStartTime: Date? {
        shared.tripOriginStartTime
    }
    
    static var currentTripDistance: CLLocationDistance {
        shared.tripDistance
    }

    static var currentTripDuration: TimeInterval {
        shared.tripDuration
    }
}
