import SwiftUI

struct TripSortingView: View {
    @Environment(\.layout) private var layout
    @ObservedObject private var viewModel = TripViewModel.shared
    
    var body: some View {
        if viewModel.emptyMessage != nil {
            VStack {
                HStack {
                    Spacer()
                    Text(viewModel.emptyMessage ?? "")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.primaryText60)
                    Spacer()
                }
                .frame(width: layout.elementWidth)
            }
            .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
            .frame(width: layout.elementWidth)
        } else {
            VStack(spacing: 6) {
                Text(TripViewModel.shared.startDate ?? "")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .frame(width: layout.elementWidth)
                HStack(spacing: 3) {
                    HStack {
                        Spacer()
                        Text(TripViewModel.shared.startTime ?? "")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.primaryText60)
                    }
                    .frame(width: layout.elementWidth * 0.3)
                    Text(TripViewModel.shared.tripDistance ?? "")
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.primaryText80)
                        .frame(width: layout.elementWidth * 0.4)
                    HStack {
                        Text(TripViewModel.shared.tripDuration ?? "")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.primaryText60)
                        Spacer()
                    }
                    .frame(width: layout.elementWidth * 0.3)
                }
                .frame(width: layout.elementWidth)
                .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
            }
            .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
            .frame(width: layout.elementWidth)
        }
    }
}

#Preview {
    TripSortingView()
}
