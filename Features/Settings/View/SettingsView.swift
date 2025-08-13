import SwiftUI

struct SettingsView: View {
    @Environment(\.layout) private var layout
    @StateObject var viewModel = SettingsViewModel()
    
    var body: some View {
        ScrollView {
            ForEach(viewModel.tripSettings, id: \.userDefaultsKey) { setting in
                switch setting.controlType {
                case .stepper:
                    SettingStepperRow(model: setting)
                    SettingStepperRow(model: setting)
                case .toggle:
                    SettingToggleRow(model: setting)
                case .menu(let options):
                    SettingMenuRow(model: setting, options: options)
                }
            }
        }
        .frame(maxWidth: layout.width.pct(0.8), maxHeight: layout.height.pct(0.4))
        
    }
}
