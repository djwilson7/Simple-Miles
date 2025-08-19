import SwiftUI

// MARK: - Sorting Option identifier
//enum SortingOption: Hashable {
//    case personal
//    case business
//    case custom
//    
//    var prefix: String {
//        switch self {
//        case .personal: return "personal"
//        case .business: return "business"
//        case .custom: return "custom"
//        }
//    }
//}

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
            let viewHeight = geo.size.height * 0.33
            let viewWidth = geo.size.width * 0.8
            let rowHeight = viewHeight * 0.33
            VStack(spacing: 8) {
                // Option 1 row (fills 1/3 height)
                rowView(tripType: .personal, isHighlighted: highlighted == .personal, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.personal: anchor]
                    }
                
                // Option 2 row (fills 1/3 height)
                rowView(tripType: .business, isHighlighted: highlighted == .business, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.business: anchor]
                    }
                // Add New row (fills 1/3 height)
                rowView(tripType: .custom, isHighlighted: highlighted == .custom, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.custom: anchor]
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
        }
    }

    @ViewBuilder
    private func rowView(tripType: TripType, isHighlighted: Bool, rowHeight: CGFloat) -> some View {
        HStack {
            Spacer()
            Text(tripType.name.capitalized)
                .font(isHighlighted ? .title : .headline)
                .foregroundColor(AppTheme.Colors.primaryText)
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
            let viewHeight = geo.size.height * 0.33
            let viewWidth = geo.size.width * 0.8
            let rowHeight = viewHeight * 0.33
            VStack(spacing: 8) {
                // Option 1 row (fills 1/3 height)
                rowView(title: "Personal", isHighlighted: highlighted == .personal, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.personal: anchor]
                    }
                
                // Option 2 row (fills 1/3 height)
                rowView(title: "Business", isHighlighted: highlighted == .business, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.business: anchor]
                    }
                // Add New row (fills 1/3 height)
                rowView(title: "Add New...", isHighlighted: highlighted == .custom, rowHeight: rowHeight)
                    .frame(width: viewWidth)
                    .contentShape(RoundedRectangle(cornerRadius: layout.radii.pill))
                    .anchorPreference(key: OptionFramesKey.self, value: .bounds) { anchor in
                        [.custom: anchor]
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
                    .glassEffect()
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

//#Preview {
//    @Previewable @Environment(\.layout) var layout
//    @Previewable @State var drag: CGSize = .zero
//    @Previewable @State var highlighted: SortingOption? = nil
//    @Previewable @State var isDragging: Bool = false
//    @Previewable @State var currentHighlightedArea: CGFloat = 0
//    @Previewable @State var optionAnchorsState: [SortingOption: Anchor<CGRect>] = [:]
//    @Previewable @State var barAnchorState: Anchor<CGRect>? = nil
//
//    GeometryReader { geometry in
//        let safeHeight = geometry.size.height - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom
//        ZStack {
//            // Map placeholder
//            Color.blue.opacity(0.3)
//                .ignoresSafeArea()
//            
//            GeometryReader { safeGeo in
//                VStack(spacing: 0) {
//                    ZStack {
//                        Color.green.opacity(0.2)
//                            .frame(height: 60)
//                            .frame(maxWidth: .infinity)
//                        VStack { Spacer(); Text("Title Bar Placeholder"); Spacer() }
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: geometry.size.height * 0.1)
//                    ZStack {
//                        GlassEffectContainer {
//                            ZStack(alignment: .bottom) {
//                                Color.yellow.opacity(0.2)
//                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                
//                                ZStack(alignment: .center) {
//                                    TripSortingBackgroundView(highlighted: highlighted)
//                                        .opacity(isDragging ? 1 : 0)
//                                        .animation(.easeInOut(duration: 0.3), value: isDragging)
//                                }
//                                .frame(maxWidth: .infinity, maxHeight: .infinity)
//                                
//                                // Dynamic context (orange) bar with anchor preference for its frame
//                                let barSize = CGSize(width: 200, height: 50)
//
//                                Color.orange.opacity(0.3)
//                                    .frame(width: barSize.width, height: barSize.height)
//                                    .clipShape(RoundedRectangle(cornerRadius: layout.radii.pill))
//                                    .glassEffect(in: RoundedRectangle(cornerRadius: layout.radii.pill))
//                                    .offset(x: drag.width, y: drag.height - geometry.safeAreaInsets.bottom) // 👈 push up
//                                    .anchorPreference(key: BarFrameKey.self, value: .bounds) { $0 }
//                                    .gesture(
//                                        DragGesture()
//                                            .onChanged { value in
//                                                drag = value.translation
//                                                isDragging = true
//                                            }
//                                            .onEnded { _ in
//                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
//                                                    drag = .zero
//                                                    isDragging = false
//                                                }
//                                            }
//                                    )
//                            }
//                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment:.bottom)
//                        }
//                        .ignoresSafeArea()
//                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//                        
//                        TripSortingTextView(highlighted: highlighted)
//                            .opacity(isDragging ? 1 : 0)
//                            .animation(.easeInOut(duration: 0.3), value: isDragging)
//                    }
//                    .ignoresSafeArea()
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
//                }
//            }
//            .frame(height: .infinity)
//            // Resolve option frames and bar frame to compute magnetic highlighting
//            .overlayPreferenceValue(OptionFramesKey.self) { optionAnchors in
//                GeometryReader { proxy in
//                    Color.clear
//                        .onAppear {
//                            optionAnchorsState = optionAnchors
//                            updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: drag)
//                        }
//                        .onChange(of: optionAnchors, initial: true) { _, newValue in
//                            optionAnchorsState = newValue
//                            updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: drag)
//                        }
//                }
//            }
//            .overlayPreferenceValue(BarFrameKey.self) { barAnchor in
//                GeometryReader { proxy in
//                    Color.clear
//                        .onAppear {
//                            barAnchorState = barAnchor
//                            updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: drag)
//                        }
//                        .onChange(of: drag, initial: true) { _, newValue in
//                            updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: drag)
//                        }
//                        .onChange(of: barAnchor, initial: true) { _, newValue in
//                            barAnchorState = newValue
//                            updateHighlight(proxy: proxy, optionAnchors: optionAnchorsState, barAnchor: barAnchorState, highlighted: &highlighted, currentHighlightedArea: &currentHighlightedArea, drag: drag)
//                        }
//                }
//            }
//        }
//    }
//}
