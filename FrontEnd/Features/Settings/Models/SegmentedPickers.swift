import SwiftUI

protocol SegmentedPickerOption: CaseIterable, Identifiable, Hashable {
    var displayName: String { get }
}

struct SegmentedPicker<T: SegmentedPickerOption & Hashable>: View where T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    
    var body: some View {
        Picker("", selection: $selection) {
            ForEach(T.allCases) { option in
                Text(option.displayName).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}
