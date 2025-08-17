//
//  SettingMenuRow.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/9/25.
//

import SwiftUI

/// A row for selecting a setting value from a menu (picker).
struct SettingMenuRow: View {
    let model: SettingModel
    let options: [String]
    @State private var selected: String
    
    init(model: SettingModel, options: [String]) {
        self.model = model
        self.options = options
        // Try to get the initial value from the model's value if it's a string, otherwise default to the first option
        if case let .string(strValue) = model.value {
            _selected = State(initialValue: strValue)
        } else {
            _selected = State(initialValue: options.first ?? "")
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(model.title)
                    .font(.body).bold()
                    .foregroundColor(AppTheme.Colors.primaryText)
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.primaryText80)
                    .lineLimit(2)
            }
            Spacer()
            Picker("", selection: $selected) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                        .font(.caption)
                        .foregroundColor(AppTheme.Colors.primaryText)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: selected) { _, newValue in
                // Update model value if needed
                // Note: model.value should be settable or you can provide a setValue method on the model
                // Example:
                // model.setValue(.string(newValue))
            }
            .glassEffect()
        }
        .padding(5)
    }
}

#Preview {
    let previewOptions = ["Option 1", "Option 2", "Option 3"]
    let previewModel = SettingModel(
        title: "Units",
        description: "Select units for distance.",
        userDefaultsKey: "units",
        controlType: .menu(options: previewOptions),
        value: .string("Option 2")
    )
    VStack {
        Spacer()
        SettingMenuRow(model: previewModel, options: previewOptions)
        Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(
            gradient: Gradient(colors: [.red, .blue]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
