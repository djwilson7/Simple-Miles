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
    var hasTrips: Bool
    
    var body: some View {
        Text(hasTrips ? payload : "No Trips To Sort")
            .foregroundColor(.white)
            .padding(.top, 15)
            .padding(.bottom, 15)
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
            DateBar(geo: proxy, payload: "Jun 31st 2025 1:25pm", isDragging: false, hasTrips: true)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.4))
    }
}
