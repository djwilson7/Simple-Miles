import SwiftUI

/// A generic menu-style picker for enums that conform to SegmentedPickerOption.
/// Uses SwiftUI's Picker with `.menu` style, binding to the same selection model
/// as the segmented picker.
///
/// Example:
/// MenuPicker(selection: $settings.themeOverride)
struct MenuPicker<T: SegmentedPickerOption>: View where T.AllCases: RandomAccessCollection {

    // MARK: - Binding
    @Binding var selection: T

    // MARK: - Environment
    @Environment(\.layout) private var layout

    // MARK: - Init
    init(selection: Binding<T>) {
        self._selection = selection
    }

    // MARK: - Body
    var body: some View {
        Picker(selection: $selection) {
            ForEach(T.allCases) { option in
                Text(option.displayName)
                    .tag(option)
            }
        } label: {
            HStack(spacing: 6) {
                Text(selection.displayName)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
        }
        .pickerStyle(.menu)
        .accessibilityLabel(Text("Options"))
    }
}
