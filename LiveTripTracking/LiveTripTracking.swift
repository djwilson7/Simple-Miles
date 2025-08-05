import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tripState: "idle", tripDistance: 0.0,
                    tripDistanceCommitted: 0.0, tripDistanceLive: 0.0,
                    tripDuration: 0.0, tripDurationCommitted: 0.0, tripDurationLive: 0.0,
                    remainingPauseTime: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let defaults = UserDefaults(suiteName: "group.i-maneo.SimpleMiles")
        let entry = SimpleEntry(
            date: Date(),
            tripState: defaults?.string(forKey: "tripState") ?? "idle",
            tripDistance: defaults?.double(forKey: "tripDistance") ?? 0.0,
            tripDistanceCommitted: defaults?.double(forKey: "tripDistanceCommitted") ?? 0.0,
            tripDistanceLive: defaults?.double(forKey: "tripDistanceLive") ?? 0.0,
            tripDuration: defaults?.double(forKey: "tripDuration") ?? 0.0,
            tripDurationCommitted: defaults?.double(forKey: "tripDurationCommitted") ?? 0.0,
            tripDurationLive: defaults?.double(forKey: "tripDurationLive") ?? 0.0,
            remainingPauseTime: defaults?.double(forKey: "remainingPauseTime")
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let defaults = UserDefaults(suiteName: "group.i-maneo.SimpleMiles")
        let entry = SimpleEntry(
            date: Date(),
            tripState: defaults?.string(forKey: "tripState") ?? "idle",
            tripDistance: defaults?.double(forKey: "tripDistance") ?? 0.0,
            tripDistanceCommitted: defaults?.double(forKey: "tripDistanceCommitted") ?? 0.0,
            tripDistanceLive: defaults?.double(forKey: "tripDistanceLive") ?? 0.0,
            tripDuration: defaults?.double(forKey: "tripDuration") ?? 0.0,
            tripDurationCommitted: defaults?.double(forKey: "tripDurationCommitted") ?? 0.0,
            tripDurationLive: defaults?.double(forKey: "tripDurationLive") ?? 0.0,
            remainingPauseTime: defaults?.double(forKey: "remainingPauseTime")
        )
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tripState: String
    let tripDistance: Double
    let tripDistanceCommitted: Double
    let tripDistanceLive: Double
    let tripDuration: Double
    let tripDurationCommitted: Double
    let tripDurationLive: Double
    let remainingPauseTime: Double?
}

private func formattedTime(_ seconds: Double) -> String {
    let minutes = Int(seconds) / 60
    let remainingSeconds = Int(seconds) % 60
    if minutes > 0 {
        return "\(minutes)m \(remainingSeconds)s"
    } else {
        return "\(remainingSeconds)s"
    }
}

private func stateColor(for state: String) -> Color {
    switch state.lowercased() {
    case "paused":
        return .orange
    case "traveling":
        return .green
    default:
        return .primary
    }
}

struct LiveTripTrackingSmallView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text(entry.tripState.capitalized)
                    .foregroundColor(stateColor(for: entry.tripState))
                    .font(.headline)
                Spacer()
            }

            HStack {
                VStack(spacing: 2) {
                    Text(String(format: "%.1f mi", entry.tripDistanceCommitted))
                        .foregroundColor(entry.tripDistanceCommitted > 0 ? .green : .white)
                        .font(.caption)
                    Text(String(format: "%.1f mi", entry.tripDistanceLive))
                        .foregroundColor(entry.tripDistanceLive > 0 ? .orange : .gray)
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))
                
                VStack(spacing: 2) {
                    Text(formattedTime(entry.tripDurationCommitted))
                        .foregroundColor(entry.tripDurationCommitted > 0 ? .green : .white)
                        .font(.caption)
                    Text(formattedTime(entry.tripDurationLive))
                        .foregroundColor(entry.tripDurationLive > 0 ? .orange : .gray)
                        .font(.caption2)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .containerBackground(.black, for: .widget)
    }
}


struct LiveTripTrackingMediumView: View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .trim(from: 0.75, to: 0.75 + min(entry.tripDistanceLive / 100.0, 1.0))
                .stroke(
                    entry.tripState.lowercased() == "paused" ? Color.orange.opacity(0.9) : Color.clear,
                    lineWidth: 3
                )
                .rotationEffect(.degrees(270))
                .animation(.linear(duration: 1.0), value: entry.tripDistanceLive)

            HStack(spacing: 12) {
                VStack(spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry.tripState.capitalized)
                        .font(.body)
                        .foregroundColor(stateColor(for: entry.tripState))
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))

                VStack(spacing: 2) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f miles", entry.tripDistanceCommitted))
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(String(format: "%.1f miles", entry.tripDistanceLive))
                        .font(.caption2)
                        .foregroundColor(
                            entry.tripState.lowercased() == "paused" ? .orange :
                            entry.tripState.lowercased() == "traveling" ? .green :
                            entry.tripDistanceLive > 0 ? .green : .gray
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
                    Text(formattedTime(entry.tripDurationCommitted))
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(formattedTime(entry.tripDurationLive))
                        .font(.caption2)
                        .foregroundColor(
                            entry.tripState.lowercased() == "paused" ? .orange :
                            entry.tripState.lowercased() == "traveling" ? .green :
                            entry.tripDurationLive > 0 ? .green : .gray
                        )
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
        }
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

struct LiveTripTracking: Widget {
    let kind: String = "LiveTripTracking"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LiveTripTrackingEntryView(entry: entry)
        }
        .configurationDisplayName("Trip Tracking")
        .description("View your current trip status and stats.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct LiveTripTrackingLargeView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.tripState.capitalized)
                .font(.title2)
                .bold()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Committed Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f mi", entry.tripDistanceCommitted))
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Distance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f mi", entry.tripDistanceLive))
                        .foregroundColor(entry.tripState == "paused" ? .orange : (entry.tripDistanceLive > 0 ? .green : .gray))
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Committed Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedTime(entry.tripDurationCommitted))
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedTime(entry.tripDurationLive))
                        .foregroundColor(entry.tripState == "paused" ? .orange : (entry.tripDurationLive > 0 ? .green : .gray))
                }
            }

            if entry.tripState == "paused", let remaining = entry.remainingPauseTime {
                Text("Ending Trip In: \(formattedTime(remaining))")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .containerBackground(.ultraThinMaterial, for: .widget)
    }
}

struct LiveTripTrackingEntryView: View {
    let entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            LiveTripTrackingSmallView(entry: entry)
        case .systemMedium:
            LiveTripTrackingMediumView(entry: entry)
        case .systemLarge:
            LiveTripTrackingLargeView(entry: entry)
        default:
            LiveTripTrackingSmallView(entry: entry)
        }
    }
}
