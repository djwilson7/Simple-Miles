import SwiftUI
import Foundation

private struct RowHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct TripStatusView: View {
    @Environment(\.layout) private var layout
    @ObservedObject var viewModel = TripStatusViewModel.shared
    @State private var rowHeight: CGFloat = 0
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left column (Distance)
            VStack(spacing: 2) {
                Text("Distance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f miles", viewModel.tripDistanceCommittedMiles))
                    .font(.body)
                    .foregroundColor(viewModel.tripDistanceCommittedMiles > 0 ? .blue : .primary)
                Text(String(format: "%.1f miles", viewModel.tripDistanceLiveMiles))
                    .font(.caption2)
                    .foregroundColor(
                        viewModel.tripState == .paused ? .orange :
                        viewModel.tripState == .traveling ? .green :
                        viewModel.tripDistanceLiveMiles > 0 ? .green : .gray
                    )
            }
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: RowHeightKey.self, value: g.size.height)
                }
            )

            Divider()
                .frame(width: 1, height: rowHeight)
                .background(Color.secondary.opacity(0.4))

            // Middle column (Status)
            VStack(spacing: 2) {
                Text("Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(viewModel.tripStateText)
                    .font(.body)
                    .foregroundColor(viewModel.tripStateColor)
            }
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: RowHeightKey.self, value: g.size.height)
                }
            )

            Divider()
                .frame(width: 1, height: rowHeight)
                .background(Color.secondary.opacity(0.4))

            // Right column (Trip Time)
            VStack(spacing: 2) {
                Text("Trip Time")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(formattedTime(viewModel.tripDurationCommitted))
                    .font(.body)
                    .foregroundColor(viewModel.tripDurationCommitted > 0 ? .blue : .primary)
                Text(formattedTime(viewModel.tripDurationLive))
                    .font(.caption2)
                    .foregroundColor(
                        viewModel.tripState == .paused ? .orange :
                        viewModel.tripState == .traveling ? .green :
                        viewModel.tripDurationLive > 0 ? .green : .gray
                    )
            }
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: RowHeightKey.self, value: g.size.height)
                }
            )
        }
        .onPreferenceChange(RowHeightKey.self) { rowHeight = $0 }
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: layout.width.pct(0.8))
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let ti = Int(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
