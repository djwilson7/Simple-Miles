import SwiftUI
import UniformTypeIdentifiers

struct SortBubble: View {
    let text: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.clear.opacity(0.001))
                .frame(width: size, height: size, alignment: .center)
            Text(text)
                .font(.system(size: size * 0.3, weight: .bold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .frame(width: size, height: size, alignment: .center)
        }
        .frame(width: size, height: size, alignment: .center)
    }
}

// Preview for rapid iteration
private struct SortBubblePreview: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 30) {
            SortBubble(text: "Personal", size: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(white: 0.6))
    }
}

#Preview {
    SortBubblePreview()
}
