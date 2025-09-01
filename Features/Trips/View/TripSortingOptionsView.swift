import SwiftUI

// MARK: - Dumb options view
struct TripSortingTextView: View {
    @Environment(\.layout) private var layout
    /// The option that should be visually highlighted. Provided by parent.
    var highlighted: TripType? = nil

    /// Visual scale values for magnetic highlighting.
    private let highlightedScale: CGFloat = 1.17
    private let dimmedScale: CGFloat = 0.92

    var body: some View {
        GeometryReader { geo in
            let viewHeight = geo.size.height * 0.5
            let viewWidth = geo.size.width * 0.8
            let rowHeight = viewHeight * 0.25
            VStack(spacing: 8) {
                rowView(tripType: .personal, isHighlighted: highlighted == .personal, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.personal: anchor]
                    }
                
                rowView(tripType: .business, isHighlighted: highlighted == .business, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.business: anchor]
                    }
                
                rowView(tripType: .custom, isHighlighted: highlighted == .custom, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.custom: anchor]
                    }
                
                rowView(tripType: .trash, isHighlighted: highlighted == .trash, rowHeight: rowHeight, labelColor: Color.red.opacity(0.8))
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.trash: anchor]
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        }
    }

    @ViewBuilder
    private func rowView(tripType: TripType, isHighlighted: Bool, rowHeight: CGFloat, labelColor: Color = AppTheme.Colors.primaryText) -> some View {
        HStack {
            Spacer()
            Text(tripType.name.capitalized)
                .font(isHighlighted ? .title : .headline)
                .foregroundColor(labelColor)
                .lineLimit(1)
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
        .frame(height: rowHeight)
        .scaleEffect(isHighlighted ? highlightedScale : dimmedScale)
    }
}

struct TripSortingBackgroundView: View {
    @Environment(\.layout) private var layout
    /// The option that should be visually highlighted. Provided by parent.
    var highlighted: TripType? = nil

    /// Visual scale values for magnetic highlighting.
    private let highlightedScale: CGFloat = 1.17
    private let dimmedScale: CGFloat = 0.92

    var body: some View {
        GeometryReader { geo in
            let viewHeight = geo.size.height * 0.5
            let viewWidth = geo.size.width * 0.8
            let rowHeight = viewHeight * 0.25
            VStack(spacing: 8) {
 
                rowView(title: "Personal", isHighlighted: highlighted == .personal, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.personal: anchor]
                    }
                
                rowView(title: "Business", isHighlighted: highlighted == .business, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.business: anchor]
                    }

                rowView(title: "Add New...", isHighlighted: highlighted == .custom, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.custom: anchor]
                    }
                
                rowView(title: "Delete", isHighlighted: highlighted == .trash, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.trash: anchor]
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        }
    }

    @ViewBuilder
    private func rowView(title: String, isHighlighted: Bool, rowHeight: CGFloat) -> some View {
        HStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.clear.opacity(0.001))
                    .applyMaterial()
            }
            .frame(width: isHighlighted ? 150 : 0, height: isHighlighted ? 50 : 0)
            .animation(.easeInOut(duration: 0.3), value: isHighlighted)
            
            Spacer()
        }
        .animation(.easeInOut(duration: 0.3), value: isHighlighted)
        .frame(height: rowHeight)
        .scaleEffect(isHighlighted ? highlightedScale : dimmedScale)
    }
}
