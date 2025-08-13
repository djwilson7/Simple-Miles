import SwiftUI

struct TripSortingView: View {
    @Environment(\.layout) private var layout
    @ObservedObject private var viewModel = TripViewModel.shared
    
    var body: some View {
        HStack {
            Text(TripViewModel.shared.currentStartDate)
                .font(.body)
                .foregroundColor(Color.white)

        }
        .frame(width: layout.width.pct(0.5), height: layout.height.pct(0.05))
    }
}

#Preview {
    // Provide a mock TripViewModel for preview
    TripSortingView()
}
