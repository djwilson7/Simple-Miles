import SwiftUI

enum SettingsFontStyle {

    // MARK: - 1. Section Headers
    static let sectionHeader: Font = .headline.weight(.bold)

    // MARK: - 2. Setting Labels
    static let settingTitle: Font = .subheadline

    // MARK: - 3. Setting Descriptions
    static let settingDescription: Font = .caption

    // MARK: - 4. Inline Value Titles
    static let inlineTitle: Font = .subheadline.weight(.medium)

    // MARK: - 5. Picker / Toggle / Stepper Values
    static let pickerText: Font = .footnote

    // MARK: - 6. Custom User Labels
    static let userInput: Font = .footnote
}
