import SwiftUI

/// Presents the draggable sort options overlay (labels and background highlights)
/// used during Review mode classification. Exposes anchor preferences for hit-testing.
struct SortOptionsView: View {

    // MARK: - Types (View-only helpers)
    enum Types {
        struct OptionFramesKey: PreferenceKey {
            static var defaultValue: [TripType: Anchor<CGRect>] = [:]
            static func reduce(
                value: inout [TripType: Anchor<CGRect>],
                nextValue: () -> [TripType: Anchor<CGRect>]
            ) {
                value.merge(nextValue(), uniquingKeysWith: { _, new in new })
            }
        }
    }

    // MARK: - Environment / Dependencies
    @Environment(\.layout) private var layout

    // MARK: - Input
    var highlighted: TripType? = nil

    // MARK: - Configuration
    private let highlightedScale: CGFloat = 1.17
    private let dimmedScale: CGFloat = 0.92

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let viewHeight = geo.size.height * 0.5
            let viewWidth = geo.size.width * 0.8
            let rowHeight = viewHeight * 0.25
            let shape = RoundedRectangle(cornerRadius: layout.cornerRadius)
            VStack(spacing: 8) {
                optionRow(tripType: .personal, isHighlighted: highlighted == .personal, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.personal: anchor]
                    }

                optionRow(tripType: .business, isHighlighted: highlighted == .business, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.business: anchor]
                    }

                optionRow(tripType: .custom, isHighlighted: highlighted == .custom, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.custom: anchor]
                    }

                optionRow(
                    tripType: .trash,
                    isHighlighted: highlighted == .trash,
                    rowHeight: rowHeight,
                    labelColor: Color.red.opacity(0.8)
                )
                .frame(width: viewWidth)
                .contentShape(shape)
                .anchorPreference(key: Types.OptionFramesKey.self, value: .bounds) { anchor in
                    [.trash: anchor]
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(shape)
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func optionRow(
        tripType: TripType,
        isHighlighted: Bool,
        rowHeight: CGFloat,
        labelColor: Color = AppTheme.Colors.primaryText
    ) -> some View {
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

// MARK: - Background Overlay
/// Background companion view that renders the material cards behind the labels
/// and publishes the same option anchors for hit-testing.
struct SortOptionsBGView: View {

    // MARK: - Environment
    @Environment(\.layout) private var layout

    // MARK: - Input
    var highlighted: TripType? = nil

    // MARK: - Configuration
    private let highlightedScale: CGFloat = 1.17
    private let dimmedScale: CGFloat = 0.92

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let viewHeight = geo.size.height * 0.5
            let viewWidth = geo.size.width * 0.8
            let rowHeight = viewHeight * 0.25
            let shape = RoundedRectangle(cornerRadius: layout.cornerRadius)
            
            VStack(spacing: 8) {
                backgroundRow(isHighlighted: highlighted == .personal, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: SortOptionsView.Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.personal: anchor]
                    }

                backgroundRow(isHighlighted: highlighted == .business, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: SortOptionsView.Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.business: anchor]
                    }

                backgroundRow(isHighlighted: highlighted == .custom, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: SortOptionsView.Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.custom: anchor]
                    }

                backgroundRow(isHighlighted: highlighted == .trash, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(shape)
                    .anchorPreference(key: SortOptionsView.Types.OptionFramesKey.self, value: .bounds) { anchor in
                        [.trash: anchor]
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(shape)
        }
    }

    // MARK: - Subviews
    @ViewBuilder
    private func backgroundRow(isHighlighted: Bool, rowHeight: CGFloat) -> some View {
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
