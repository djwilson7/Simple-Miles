import SwiftUI
import ActivityKit
import WidgetKit
import Intents

struct ActivityView: View {
    let context: ActivityViewContext<TripActivityAttributes>
    
    var body: some View {
        ZStack {
            if context.state.state.lowercased() == "paused" {
                let sweepStart = 0.75
                let sweepProgress = min(context.state.sweepProgress, 1.0)
                if sweepStart + sweepProgress <= 1.0 {
                    RoundedRectangle(cornerRadius: 24)
                        .trim(from: sweepStart, to: sweepStart + sweepProgress)
                        .stroke(Color.orange.opacity(0.9), lineWidth: 7)
                        .animation(.linear(duration: 1.0), value: sweepProgress)
                } else {
                    // First segment: from sweepStart to 1.0
                    RoundedRectangle(cornerRadius: 24)
                        .trim(from: sweepStart, to: 1.0)
                        .stroke(Color.orange.opacity(0.9), lineWidth: 7)
                        .animation(.linear(duration: 1.0), value: sweepProgress)
                    // Second segment: from 0.0 to overflow
                    RoundedRectangle(cornerRadius: 24)
                        .trim(from: 0.0, to: (sweepStart + sweepProgress) - 1.0)
                        .stroke(Color.orange.opacity(0.9), lineWidth: 7)
                        .animation(.linear(duration: 1.0), value: sweepProgress)
                }
            }

            TripStatusView(
                state: context.state.state,
                committedDistance: context.state.tripDistanceCommitted,
                liveDistance: context.state.tripDistanceLive,
                committedDuration: context.state.tripDurationCommitted,
                liveDuration: context.state.tripDurationLive,
                remainingPauseTime: context.state.remainingPauseTime
            )
            .padding()
        }
        .activityBackgroundTint(Color.black)
        .activitySystemActionForegroundColor(Color.white)
    }
}

private func stateColor(for state: String) -> Color {
    switch state.lowercased() {
    case "idle":
        return .gray
    case "paused":
        return .orange
    case "traveling":
        return .green
    default:
        return .primary
    }
}

private func formattedTime(_ seconds: TimeInterval) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    if minutes > 0 {
        return "\(minutes)m \(remainingSeconds)s"
    } else {
        return "\(remainingSeconds)s"
    }
}

struct TripStatusView: View {
    let state: String
    let committedDistance: Double
    let liveDistance: Double
    let committedDuration: TimeInterval
    let liveDuration: TimeInterval
    let remainingPauseTime: TimeInterval?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(state.capitalized)
                        .font(.body)
                        .foregroundColor(stateColor(for: state))
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))

                VStack(spacing: 2) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: "%.1f miles", committedDistance))
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(String(format: "%.1f miles", liveDistance))
                        .font(.caption2)
                        .foregroundColor(
                            state.lowercased() == "paused" ? .orange :
                            state.lowercased() == "traveling" ? .green :
                            liveDistance > 0 ? .green : .gray
                        )
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))

                VStack(spacing: 2) {
                    Text("Trip Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formattedTime(committedDuration))
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(formattedTime(liveDuration))
                        .font(.caption2)
                        .foregroundColor(
                            state.lowercased() == "paused" ? .orange :
                            state.lowercased() == "traveling" ? .green :
                            liveDuration > 0 ? .green : .gray
                        )
                }
                .frame(maxWidth: .infinity)
            }

            if state.lowercased() == "paused" {
                HStack {
                    Text("Ending Trip In:")
                        .font(.caption)
                        .bold()

                    Text(formattedTime(remainingPauseTime ?? 0))
                        .font(.caption)
                        .foregroundColor(.orange)
                        .bold()

                    Spacer()

                    Button(intent: ExtendPauseIntent()) {
                        Text("Extend Pause")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.orange, lineWidth: 2)
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(8)
            }
        }
    }
}

