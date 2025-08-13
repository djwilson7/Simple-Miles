import Foundation
import SwiftUI

final class SettingsViewModel: ObservableObject {

    @Published var isInView: Bool = false

    var tripSettings: [SettingModel] {
        AppSettings.shared.tripSettings
    }
}
