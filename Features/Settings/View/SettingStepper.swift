import SwiftUI

struct SettingStepperRow: View {
    let model: SettingModel
    let step: Double
    let range: ClosedRange<Double>
    var displayFormatter: (Double) -> String
    
    @State private var value: Double
    
    init(
        model: SettingModel,
        displayFormatter: @escaping (Double) -> String = { String(format: "%.1f", $0) }
    ) {
        self.model = model
        self.displayFormatter = displayFormatter
        // Extract step/range from model.controlType
        if case let .stepper(min, max, step) = model.controlType {
            self.step = step
            self.range = min...max
        } else {
            self.step = 0.1
            self.range = 0.1...1.5
        }
        // Extract value from model.value
        if case let .double(v) = model.value {
            _value = State(initialValue: v)
        } else {
            _value = State(initialValue: 0.0)
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text(model.title)
                    .font(.body).bold()
                    .foregroundColor(AppTheme.Colors.primaryText)
                Spacer()
                Text(displayFormatter(value))
                    .font(.body)
                    .foregroundColor(AppTheme.Colors.primaryText)
                    .lineLimit(1)
                Stepper("", value: $value, in: range, step: step, onEditingChanged: { _ in
                    model.value = .double(value)
                    UserDefaults.standard.set(value, forKey: model.userDefaultsKey)
                })
                .labelsHidden()
                .glassEffect()
            }
            HStack {
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.primaryText80)
                    .lineLimit(2)
                Spacer()
            }
        }
        .padding(5)
    }
}
