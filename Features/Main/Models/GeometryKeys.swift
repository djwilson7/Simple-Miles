import SwiftUI

/// Shared preference key used by child views (e.g., TripSortingTextView / TripSortingBackgroundView)
/// to bubble up the layout anchors (`Anchor<CGRect>`) for each sorting option.
/// Parent views (e.g., MainView) read this key via `.overlayPreferenceValue` and resolve the anchors
/// into concrete `CGRect`s using the provided `GeometryProxy`.
struct OptionFramesKey: PreferenceKey {
    static var defaultValue: [TripType: Anchor<CGRect>] = [:]

    static func reduce(value: inout [TripType: Anchor<CGRect>],
                       nextValue: () -> [TripType: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// Shared preference key used by the context bar to publish its own frame anchor upward.
/// Parent views resolve this anchor to a `CGRect` in the same overlay subtree/coordinate space.
struct BarFrameKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        if let next = nextValue() {
            value = next
        }
    }
}

/// Universal preference key for child views rendered inside the Dynamic Context Bar
/// to report their desired total height upward. The parent (DynamicContextBar) reads this
/// and animates its height accordingly.
struct DynamicContextBarDesiredHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


struct DynamicContextBarDesiredWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
