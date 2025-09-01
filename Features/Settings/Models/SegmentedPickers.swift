import SwiftUI

protocol SegmentedPickerOption: CaseIterable, Identifiable, Hashable {
    var displayName: String { get }
}

protocol SegmentedColorOption: SegmentedPickerOption {
    /// The representative color for this option. Return nil to use the default background.
    var swatchColor: Color? { get }
}

struct SegmentedPicker<T: SegmentedPickerOption & Hashable>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(T.allCases) { option in
                Text(option.displayName).tag(option)
                    .uiText(.title)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct SegmentedColorPicker<T: SegmentedPickerOption & Hashable>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(T.allCases) { option in
                Text(option.displayName).tag(option)
                    .uiText(.title)
            }
        }
        .pickerStyle(.segmented)
        .tint(.orange)
    }
}
