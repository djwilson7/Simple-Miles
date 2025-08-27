import SwiftUI

struct DynamicMetaDataBar: View {
    @Environment(\.layout) private var layout
    @State private var isPressed = false

    let text: String?

    var body: some View {
        let text = text ?? ""
        Text(text)
            .font(.subheadline)
            .foregroundColor(AppTheme.Colors.primaryText)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(in: RoundedRectangle(cornerRadius: layout.radii.pill))
            .scaleEffect(isPressed ? 1.05 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    isPressed.toggle()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
            }
    }
}

struct DynamicMetaDataBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VStack(alignment: .leading, spacing: 20) {
                DynamicMetaDataBar(text: "8:45 AM")
                DynamicMetaDataBar(text: "1h 15min")
            }
            .padding()
            .previewDisplayName("Stacked Bars")

            HStack(spacing: 20) {
                DynamicMetaDataBar(text: "8:45 AM")
                DynamicMetaDataBar(text: "1h 15min")
            }
            .padding()
            .preferredColorScheme(.dark)
            .previewDisplayName("Stacked Bars Dark")
            
            DynamicMetaDataBar(text: "A Bar by itself")
                .padding()
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Single Bar Light")

            DynamicMetaDataBar(text: "A Bar by itself")
                .padding()
                .previewLayout(.sizeThatFits)
                .preferredColorScheme(.dark)
                .previewDisplayName("Single Bar Dark")
        }
    }
}
