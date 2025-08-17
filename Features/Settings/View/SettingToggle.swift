//
//  SettingToggle.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 8/9/25.
//

import SwiftUI

struct SettingToggleRow: View {
    let model: SettingModel
    @State private var isOn: Bool

    init(model: SettingModel) {
        self.model = model
        if case let .bool(b) = model.value {
            _isOn = State(initialValue: b)
        } else {
            _isOn = State(initialValue: false)
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
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _, newValue in
                    model.value = .bool(newValue)
                    UserDefaults.standard.set(newValue, forKey: model.userDefaultsKey)
                }
                .glassEffect()
        }
        .padding(5)
    }
}

#Preview {
    let previewModel = SettingModel(
        title: "Live Activities",
        description: "Should we display live activities when in non active state?",
        userDefaultsKey: "preview_liveActivities",
        controlType: .toggle,
        value: .bool(true)
    )
    VStack {
        Spacer()
        SettingToggleRow(
            model: previewModel
        )
        Spacer()
    }
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity
    )
    .background(
        LinearGradient(
            gradient: Gradient(
                colors: [.red, .blue]
            ),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
