import ActivityKit
import Foundation

struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var tripDistanceCommitted: Double
        var tripDistanceLive: Double
        var tripDurationCommitted: TimeInterval
        var tripDurationLive: TimeInterval
        var state: String
        var sweepProgress: CGFloat
        var remainingPauseTime: TimeInterval?
    }
}
