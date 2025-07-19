//
//  DeveloperPanelView.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import SwiftUI

struct DeveloperPanelView: View {
    @StateObject var viewModel: DeveloperPanelViewModel

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Form {
                        Section(header: Text("Trip Recording")) {
                            HStack {
                                Text("Trip Status:")
                                Spacer()
                                Text(tripStatusLabel())
                                    .fontWeight(.semibold)
                                    .foregroundColor(tripStatusColor())
                            }

                            Text("Distance: \(String(format: "%.2f", viewModel.currentDistance * 0.000621371)) mi")
                            Text("Logged Coords: \(viewModel.loggedTripCoords)")
                            Text("Elapsed Time: \(formattedTime(viewModel.elapsedTime))")
                        }

                        Section(header: Text("Session State")) {
                            Text("Status: \(viewModel.isPaused ? "Paused" : (viewModel.isTracking ? "Tracking" : "Idle"))")

                            HStack {
                                Text("Paused: \(formattedTime(viewModel.remainingPauseTime))")
                                    .font(.body)
                                    .foregroundColor(viewModel.isPaused ? .red : .gray)

                                Spacer()

                                Button("Extend") {
                                    viewModel.resetPauseTimer()
                                }
                                .buttonStyle(.bordered)
                                .disabled(!viewModel.isPaused)
                                .opacity(viewModel.isPaused ? 1.0 : 0.3)
                            }

                            Button {
                                viewModel.forceEndTrip()
                            } label: {
                                Label("End Session Now", systemImage: "stop.circle.fill")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(Color.red)
                                    .cornerRadius(8)
                            }

                            VStack(alignment: .leading) {
                                Text("Speed Threshold: \(String(format: "%.1f", viewModel.resumeSpeedThreshold)) m/s")
                                Slider(value: $viewModel.resumeSpeedThreshold, in: 0...10, step: 0.1)

                                Text("Distance Threshold: \(Int(viewModel.resumeDistanceThreshold)) m")
                                Slider(value: $viewModel.resumeDistanceThreshold, in: 0...500, step: 10)
                            }
                            .padding(.top, 8)
                        }

                        Section(header: Text("Export Trips")) {
                            Button("Export All as CSV") {
                                viewModel.exportAllTripsAsCSV()
                            }
                            Button("Export All as JSON") {
                                viewModel.exportAllTripsAsJSON()
                            }

                            Button("Clear All Trips") {
                                viewModel.clearAllTrips()
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    .frame(height: geometry.size.height * 0.5)

                    LiveLocationMapView(viewModel: MapViewModel())
                        .aspectRatio(1, contentMode: .fit)
                        .padding()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 4)
                        .overlay(
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Debug Distance: \(viewModel.currentDistance)")
                                Text("Debug Logged Coords: \(viewModel.loggedTripCoords)")
                                Text("Debug Elapsed: \(formattedTime(viewModel.elapsedTime))")
                                Text("Debug Paused: \(viewModel.isPaused.description)")
                                Text("Debug Tracking: \(viewModel.isTracking.description)")
                            }
                            .font(.caption)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                            .padding(),
                            alignment: .topLeading
                        )
                }

                if viewModel.showToast {
                    VStack {
                        Spacer()
                        Text(viewModel.toastMessage)
                            .font(.footnote)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        viewModel.showToast = false
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.showToast)
                }
            }
            .navigationTitle("Developer Tools")
            .sheet(isPresented: $viewModel.exportLauncher.isPresenting, onDismiss: {
                viewModel.exportLauncher.reset()
            }) {
                if let url = viewModel.exportLauncher.exportURL {
                    ShareSheet(fileURL: url)
                }
            }
        }
    }

    private func formattedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func tripStatusLabel() -> String {
        if viewModel.isPaused {
            return "Paused"
        } else if viewModel.isTracking {
            return "Tracking"
        } else {
            return "Idle"
        }
    }

    private func tripStatusColor() -> Color {
        if viewModel.isPaused {
            return .orange
        } else if viewModel.isTracking {
            return .green
        } else {
            return .gray
        }
    }
}
