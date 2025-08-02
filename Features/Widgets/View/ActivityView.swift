import SwiftUI
import ActivityKit
import WidgetKit

struct ActivityView: View {
    let context: ActivityViewContext<TripActivityAttributes>

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .trim(from: 0.75, to: 0.75 + min(context.state.sweepProgress, 1.0))
                .stroke(
                    context.state.state.lowercased() == "paused" ? Color.orange.opacity(0.9) : Color.clear,
                    lineWidth: 3
                )
                .rotationEffect(.degrees(270))
                .animation(.linear(duration: 1.0), value: context.state.sweepProgress)

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

                    Button("Extend Pause") {
                        // Action placeholder
                    }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.roundedRectangle(radius: 8))
                    .tint(.orange)
                    .controlSize(.regular)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(8)
            }
        }
    }
}
