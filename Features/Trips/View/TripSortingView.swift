import SwiftUI

struct TripSortingView: View {
    @Environment(\.layout) private var layout
    @ObservedObject private var viewModel = TripViewModel.shared
    
    var body: some View {
        if viewModel.emptyMessage != nil {
            HStack {
                Spacer()
                Text(viewModel.emptyMessage ?? "")
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.primaryText60)
                Spacer()
            }
            .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
            .frame(width: layout.width.pct(0.5))
            .background(
                GeometryReader { g in
                    Color.clear
                        .preference(key: DynamicContextBarDesiredHeightKey.self, value: g.size.height)
                        .preference(key: DynamicContextBarDesiredWidthKey.self, value: g.size.width)
                }
            )
        } else {
            HStack(alignment: .center, spacing: 6) {
//                Text(TripViewModel.shared.startTime ?? "")
//                    .font(.caption)
//                    .foregroundColor(AppTheme.Colors.primaryText60)
//                    .lineLimit(1)
                VStack(spacing: 4) {
                    Text(TripViewModel.shared.startDate ?? "")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.primaryText)
                        .lineLimit(1)
                    Text(TripViewModel.shared.tripDistance ?? "")
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.primaryText80)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .layoutPriority(1)
//                Text(TripViewModel.shared.tripDuration ?? "")
//                    .font(.caption)
//                    .foregroundColor(AppTheme.Colors.primaryText60)
//                    .lineLimit(1)
            }
            .frame(width: layout.width.pct(0.5))
            .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
            .padding(10)
            .background(
                GeometryReader { g in
                    Color.clear
                        .preference(key: DynamicContextBarDesiredHeightKey.self, value: g.size.height)
                        .preference(key: DynamicContextBarDesiredWidthKey.self, value: g.size.width)
                }
            )
        }
    }
}

#Preview {
    TripSortingView()
}
