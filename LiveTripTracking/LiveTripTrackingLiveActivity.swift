//
//  LiveTripTrackingLiveActivity.swift
//  LiveTripTracking
//
//  Created by Invictus Maneo on 8/1/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

private func formattedTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    if minutes > 0 {
        return "\(minutes)m \(remainingSeconds)s"
    } else {
        return "\(remainingSeconds)s"
    }
}

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

struct LiveTripTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TripActivityAttributes.self) { context in
            ActivityView(context: context)
                .containerBackground(Color.clear, for: .widget)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    TripStatusView(
                        state: context.state.state,
                        committedDistance: context.state.tripDistanceCommitted,
                        liveDistance: context.state.tripDistanceLive,
                        committedDuration: context.state.tripDurationCommitted,
                        liveDuration: context.state.tripDurationLive,
                        remainingPauseTime: context.state.remainingPauseTime
                    )
                    .containerBackground(.ultraThinMaterial.opacity(0.001), for: .widget)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TripStatusView(
                        state: context.state.state,
                        committedDistance: context.state.tripDistanceCommitted,
                        liveDistance: context.state.tripDistanceLive,
                        committedDuration: context.state.tripDurationCommitted,
                        liveDuration: context.state.tripDurationLive,
                        remainingPauseTime: context.state.remainingPauseTime
                    )
                    .containerBackground(.ultraThinMaterial.opacity(0.001), for: .widget)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TripStatusView(
                        state: context.state.state,
                        committedDistance: context.state.tripDistanceCommitted,
                        liveDistance: context.state.tripDistanceLive,
                        committedDuration: context.state.tripDurationCommitted,
                        liveDuration: context.state.tripDurationLive,
                        remainingPauseTime: context.state.remainingPauseTime
                    )
                    .containerBackground(.ultraThinMaterial.opacity(0.001), for: .widget)
                }
            } compactLeading: {
                let liveMiles = context.state.tripDistanceLive
                Text(String(format: "%.1fmi", liveMiles))
                    .font(.caption)
                    .foregroundColor(liveMiles > 0 ? .orange : .gray)
                    .containerBackground(.ultraThinMaterial.opacity(0.001), for: .widget)
            } compactTrailing: {
                let liveSeconds = context.state.tripDurationLive
                Text(formattedTime(liveSeconds))
                    .font(.caption)
                    .foregroundColor(liveSeconds > 0 ? .orange : .gray)
                    .containerBackground(.ultraThinMaterial.opacity(0.001), for: .widget)
            } minimal: {
                Text(context.state.state.capitalized)
                    .font(.caption)
                    .containerBackground(.ultraThinMaterial.opacity(0.001), for: .widget)
            }
        }
    }
}

