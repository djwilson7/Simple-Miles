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
    
    private var hasCommitedDist: Bool {
        viewModel.tripDistanceCommittedMiles > 0
    }
    
    private var hasCommitedDur: Bool {
        viewModel.tripDurationCommitted > 0
    }
    
    private var showCommited: Bool {
        hasCommitedDist || hasCommitedDur
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left column (Distance)
            VStack(spacing: 6) {
                Text(DistanceUtility.formatter(meters: viewModel.tripDistanceLiveMiles))
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                if showCommited {
                    Text(DistanceUtility.formatter(meters: viewModel.tripDistanceCommittedMiles))
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.primaryText80)
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: RowHeightKey.self, value: g.size.height)
                }
            )
            
            Divider()
                .frame(width: 1, height: rowHeight)
                .background(AppTheme.Colors.primaryText50)
            
            // Middle column (Status)
            VStack(spacing: 6) {
                Spacer()
                Text(viewModel.tripStateText)
                    .font(.headline).bold().monospaced()
                    .foregroundColor(AppTheme.Colors.primaryText)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(
                GeometryReader { g in
                    Color.clear.preference(key: RowHeightKey.self, value: g.size.height)
                }
            )
            
            Divider()
                .frame(width: 1, height: rowHeight)
                .background(AppTheme.Colors.primaryText50)
            
            // Right column (Trip Time)
            VStack(spacing: 6) {
                Text(TimeUtility.formatter(viewModel.tripDurationLive))
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                if showCommited {
                    Text(TimeUtility.formatter(viewModel.tripDurationCommitted))
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.primaryText80)
                }
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
}
