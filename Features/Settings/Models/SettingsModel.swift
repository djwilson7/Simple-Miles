

import Foundation

final class SettingItem {
    let title: String
    let description: String
    private(set) var value: Double

    init(title: String, description: String, value: Double) {
        self.title = title
        self.description = description
        self.value = value
    }

    func set(value newValue: Double) {
        self.value = newValue
    }
}
