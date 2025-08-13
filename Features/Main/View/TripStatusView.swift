import SwiftUI
import Foundation

struct TripStatusView: View {
    @Environment(\.layout) private var layout
    @ObservedObject var viewModel = TripStatusViewModel.shared

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 0) {
                

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

                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))
                
                VStack(spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.tripStateText)
                        .font(.body)
                        .foregroundColor(viewModel.tripStateColor)
                }
                .frame(maxWidth: .infinity)

                Divider()
                    .frame(width: 1, height: 28)
                    .background(Color.secondary.opacity(0.4))
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
            }
        }
        .frame(width: layout.width.pct(0.8))
        .background(Color.clear)
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
