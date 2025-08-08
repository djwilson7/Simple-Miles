import SwiftUI

struct SystemControlButton: View {
    let icon: String
    let opacity: Double
    let padding: CGFloat
    let color: Color
    let action: () -> Void

    // Provide default values including color
    init(
        icon: String,
        opacity: Double = 1.0,
        padding: CGFloat = 5,
        color: Color = .primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.opacity = opacity
        self.padding = padding
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Color.white.opacity(0.001)
                    .clipShape(Circle())
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .medium))
                    .foregroundStyle(color)
            }
            .opacity(opacity)
            .frame(width: 30, height: 30)
            .padding(padding)
        }
    }
}


#Preview("SystemControlButton Examples") {
    VStack(spacing: 32) {
        SystemControlButton(icon: "gear", opacity: 1.0, color: .yellow) {
            print("Gear tapped")
        }
        .glassEffect(.clear)
        
        SystemControlButton(icon: "chevron.backward", opacity: 0.5, color: .accentColor) {
            print("Back tapped")
        }
        .glassEffect(.clear)
    }
    .padding()
    .background(Color.black.opacity(0.9))
}
