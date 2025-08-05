import SwiftUI

struct TripCardView: View {
    let segment: TripSegment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formattedMonthDayYear(segment.startTimestamp))
                    .font(.headline)
                Spacer()
                Text(formattedTimeOnly(segment.startTimestamp))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Distance:")
                    .font(.caption)
                    .bold()
                Text(formattedMiles(segment.distance))
                    .font(.caption)
            }

            HStack {
                Text("Duration:")
                    .font(.caption)
                    .bold()
                Text(formattedDuration(from: segment.duration))
                    .font(.caption2)
            }

            HStack {
                Spacer()
                Text(segment.tripType.name.capitalized)
                    .font(.footnote)
                    .italic()
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .shadow(radius: 2)
        .background(Color(.systemBackground).opacity(0.001))
    }

    private func formattedMonthDayYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formattedTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }

    private func formattedMiles(_ meters: Double) -> String {
        let miles = meters / 1609.34
        return String(format: "%.2f mi", miles)
    }

    private func formattedDuration(from duration: TimeInterval) -> String {
        let interval = Int(duration)
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
