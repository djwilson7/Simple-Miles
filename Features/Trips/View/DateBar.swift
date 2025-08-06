//
//  DateBar.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/4/25.
//

import SwiftUI

struct DateBar: View {
    var geo: GeometryProxy
    var payload: String
    var isDragging: Bool
    
    var body: some View {
        Text(payload)
            .foregroundColor(.white)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .minimumScaleFactor(0.0)
            .frame(width: geo.size.width * 0.5)
            .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 50))
            .shadow(color: Color.accentColor.opacity(isDragging ? 0.5 : 0), radius: isDragging ? 14 : 0)
    }
}

#Preview {
    GeometryReader { proxy in
        VStack(alignment: .center) {
            Spacer()
            DateBar(geo: proxy, payload: "Jun 31st 2025 1:25pm", isDragging: false)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.4))
    }
}
