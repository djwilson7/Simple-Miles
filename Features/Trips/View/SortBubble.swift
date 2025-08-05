import SwiftUI
import UniformTypeIdentifiers

struct SortBubble: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 20, weight: .bold))
            .frame(width: 75, height: 75, alignment: .center)
            .padding(40)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.4)
            .glassEffect(.clear, in: Circle())
            .lineLimit(1)
    }
}

// Preview for rapid iteration
private struct SortBubblePreview: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 30) {
            SortBubble(text: "Personal")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(white: 0.6))
    }
}

#Preview {
    SortBubblePreview()
}
