//
//  MapContainerView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import SwiftUI

struct MapContainerView: View {
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        ZStack {
            MapView(segments: $viewModel.segments)
                .edgesIgnoringSafeArea(.all)

            // Placeholder for floating controls
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        // Settings action
                    }) {
                        Image(systemName: "gearshape")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }

                Spacer()

                HStack {
                    Spacer()
                    Button(action: {
                        // Main menu action
                    }) {
                        Image(systemName: "line.3.horizontal")
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.loadSegments()
        }
    }
}

#Preview {
    MapContainerView()
}
