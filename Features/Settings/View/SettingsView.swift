import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        VStack(spacing: 16) {
            makeStepperRow(
                title: settings.minTripDistance.title,
                description: settings.minTripDistance.description,
                value: $settings.minimumTripDistance,
                displayText: formatDistance(settings.minimumTripDistance),
                step: 0.1,
                range: 0.1...1.5
            )
            
            makeStepperRow(
                title: settings.pauseTimerDuration.title,
                description: settings.pauseTimerDuration.description,
                value: $settings.pauseTimer,
                displayText: formatTime(settings.pauseTimer),
                step: 30,
                range: 90...300
            )
            
            Spacer()
        }
        .padding(5)
    }
    
    private func makeStepperRow(
        title: String,
        description: String,
        value: Binding<Double>,
        displayText: String,
        step: Double,
        range: ClosedRange<Double>,
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            customStepper(
                value: value,
                step: step,
                range: range,
                displayText: displayText
            )
        }
        .padding(.horizontal)
    }
    
    
    private func customStepper(
        value: Binding<Double>,
        step: Double,
        range: ClosedRange<Double>,
        displayText: String
    ) -> some View {
        HStack(spacing: 8) {
            Button(action: {
                value.wrappedValue = max(value.wrappedValue - step, range.lowerBound)
            }) {
                Text("-")
                    .font(.headline)
                    .padding(.horizontal, 4)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)

            Text(displayText)
                .font(.caption)
                .frame(minWidth: 100, alignment: .center)

            Button(action: {
                value.wrappedValue = min(value.wrappedValue + step, range.upperBound)
            }) {
                Text("+")
                    .font(.headline)
                    .padding(.horizontal, 4)
                    .foregroundColor(.green)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func formatDistance(_ value: Double) -> String {
        return String(format: "%.1fmi", value)
    }

    private func formatTime(_ value: Double) -> String {
        let seconds = Int(value)
        if seconds < 60 {
            return "\(seconds)s"
        } else {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes)m \(remainingSeconds)s"
        }
    }
}

