import SwiftUI

/// Displays the current trip’s basic details in the review context bar,
/// or an empty message when there is nothing to review. Reports its intrinsic
/// size via preferences so the surrounding bar can size itself.
struct SortView: View {

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout
    @ObservedObject private var viewModel = SortViewModel.shared

    // MARK: - Body
    var body: some View {
        Group {
            if viewModel.emptyMessage != nil {
                emptyState
            } else {
                content
            }
        }
        .preference(key: DynamicContextBarDesiredHeightKey.self, value: 50) // Stable height for sort
        .preference(key: DynamicContextBarDesiredWidthKey.self, value: layout.halfBarWidth - 32)
    }

    // MARK: - Subviews
    private var emptyState: some View {
        HStack {
            Spacer()
            Text(viewModel.emptyMessage ?? "")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primaryText60)
            Spacer()
        }
    }

    private var content: some View {
        VStack(spacing: 4) {
            Text(SortViewModel.shared.startDate ?? "")
                .font(.headline)
                .foregroundColor(AppTheme.Colors.primaryText)
            
            Text(SortViewModel.shared.tripDistance ?? "")
                .font(.body)
                .foregroundColor(AppTheme.Colors.primaryText80)
        }
    }
}
