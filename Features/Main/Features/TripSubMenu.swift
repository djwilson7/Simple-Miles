import SwiftUI

/// A lightweight, reusable submenu for a given trip type.
/// For now it just shows two actions: Review Trips and Summary Stats.
/// You can present this anywhere; caller provides the callbacks.
struct TripSubMenu: View {
    @ObservedObject private var viewModel = TripSubMenuViewModel.shared
    @Environment(\.layout) private var layout
    
    var tripTypeName: String? {
        viewModel.currentTripType?.name
    }

    var onReview: () -> Void {
        { [viewModel] in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            viewModel.hide()
            MainStateDriver.shared.mainState = .review
            Log("Entering Review State for \(String(describing: tripTypeName))")
        }
    }

    var onSummary: () -> Void {
        { [viewModel] in
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            viewModel.hide()
            MainStateDriver.shared.mainState = .summary
            Log("Entering Summary State for \(String(describing: tripTypeName))")
        }
    }
    
    var body: some View {
        let hasTripType = viewModel.currentTripType != nil
        let isVisible = viewModel.isVisible
        var reviewText: String { hasTripType ? "\(tripTypeName!.capitalized) Trips" : "" }
        var summaryText: String { hasTripType ? "\(tripTypeName!.capitalized) Summary" : "" }
        
        // Card-like container
        VStack(spacing: 12) {
            // Menu buttons
            VStack(spacing: 0) {
                Button(action: onReview) {
                    HStack {
                        Image(systemName: "rectangle.and.text.magnifyingglass")
                            .scaleEffect(isVisible ? 1 : 0.01)
                        Text(reviewText)
                            .scaleEffect(isVisible ? 1 : 0.01)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                            .scaleEffect(isVisible ? 1 : 0.01)

                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .scaleEffect(isVisible ? 1 : 0.01)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .buttonStyle(.plain)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.01)
                .accessibilityIdentifier("TripSubMenu.review")

                Button(action: onSummary) {
                    HStack {
                        Image(systemName: "chart.bar")
                            .scaleEffect(isVisible ? 1 : 0.01)
                        Text(summaryText)
                            .font(.body)
                            .scaleEffect(isVisible ? 1 : 0.01)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .scaleEffect(isVisible ? 1 : 0.01)

                    }
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .scaleEffect(isVisible ? 1 : 0.01)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .buttonStyle(.plain)
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.01)
                .accessibilityIdentifier("TripSubMenu.summary")
            }
        }
        .frame(maxWidth: isVisible ? layout.width.pct(0.7) : 0, maxHeight: isVisible ? layout.height.pct(0.15) : 0)
        .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        .glassEffect(in: RoundedRectangle(cornerRadius: layout.radii.pill))
        .shadow(radius: 8, y: 3)
        .padding(.horizontal, 50)
        .allowsHitTesting(isVisible)
        .accessibilityHidden(!isVisible)
        .scaleEffect(isVisible ? 1 : 0.01)
    }
}
