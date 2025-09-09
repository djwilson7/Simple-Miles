import SwiftUI

/// A lightweight, reusable segmented control for enums.
/// Conform your enum to SegmentedPickerOption and bind `selection` to use.
///
/// Example:
/// enum ThemeOverride: String, CaseIterable, SegmentedPickerOption {
///     case system, light, dark
///     var displayName: String { rawValue.capitalized }
/// }
/// SegmentedPicker(selection: $settings.themeOverride)
protocol SegmentedPickerOption: CaseIterable, Identifiable, Hashable {
    /// Human‑readable label for each segment.
    var displayName: String { get }
}

/// Generic segmented picker for enums conforming to SegmentedPickerOption.
/// Requires that `AllCases` is a RandomAccessCollection for efficient iteration.
struct SegmentedPicker<T: SegmentedPickerOption>: View where T.AllCases: RandomAccessCollection {

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
        Picker("", selection: $selection) {
            ForEach(T.allCases) { option in
                Text(option.displayName)
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(Text("Options"))
    }
}
