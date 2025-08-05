//
//  DateBar.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/4/25.
//

import SwiftUI

struct DateBar: View {
    var width: CGFloat
    var payload: String
    
    var body: some View {
        HStack{
            Text(payload)
                .lineLimit(1)
                .padding(.leading, 10)
                .padding(.trailing, 10)
                .padding(.top, 15)
                .padding(.bottom, 15)
        }
        .frame(width: width)
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 50))
    }
}

#Preview {
    GeometryReader { proxy in
        let computedWidth = proxy.size.width * 0.5
        VStack(alignment: .center) {
            Spacer()
            DateBar(width: computedWidth, payload: "Jun 31st 2025 1:25pm")
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.4))
    }
}
