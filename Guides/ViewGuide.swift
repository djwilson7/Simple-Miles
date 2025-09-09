//
//  FileGuide.swift
//  SimpleMiles
//
//  File Guide for "View"
//
//  Purpose:
//  A focused, copy‑pasteable guide for structuring SwiftUI View files.
//  Keep this concise and opinionated so every View looks and feels the same.
//

// MARK: - What belongs in a View file
/*
 - One primary type: struct MyFeatureView: View
 - Minimal logic: delegate orchestration and state management to a ViewModel
 - Local, view-only helpers: tiny subviews, modifiers, PreferenceKeys
 - Previews at the bottom
*/

// MARK: - Section Order (for all View files)
/*
 1) Imports (Apple first, then project)
 2) File-level doc (1–2 lines: what this view does)
 3) Primary type declaration (struct SomeView: View)
 4) Nested Types (private/internal) used only by this view
    - PreferenceKeys, small subviews, local constants
 5) Stored Properties
    - Environment / EnvironmentObject
    - Dependencies (let)
    - Bindings (@Binding)
    - State (@State, @StateObject, @ObservedObject)
    - Configuration constants (let)
    - Computed properties (derived state)
 6) Init (if needed)
 7) Body (var body: some View)
 8) Subviews (private computed vars returning View)
 9) Actions / Private helpers
10) Previews (#Preview)
*/

// MARK: - Naming & Scope
/*
 - Name the file and type the same (MapView.swift → MapView)
 - Keep small helpers nested or fileprivate to avoid polluting the module
 - Group related properties (Bindings together, State together, etc.)
 - Use // MARK: consistently; no floating code outside a section
*/

// MARK: - Copy/Paste Template (Minimal View)
/*
import SwiftUI

/// Short summary: what this view renders and when to use it.
struct FeatureView: View {

    // MARK: - Environment / Dependencies
    @Environment(\.colorScheme) private var colorScheme
    private let formatter: DistanceFormatter

    // MARK: - Bindings
    @Binding var isPresented: Bool

    // MARK: - State
    @State private var isAnimating = false
    @StateObject private var viewModel = FeatureViewModel()

    // MARK: - Configuration
    private let cornerRadius: CGFloat = 12

    // MARK: - Computed
    private var titleText: String { viewModel.title }

    // MARK: - Init
    init(isPresented: Binding<Bool>, formatter: DistanceFormatter = .init()) {
        self._isPresented = isPresented
        self.formatter = formatter
    }

    // MARK: - Body
    var body: some View {
        content
            .onAppear(perform: onAppear)
            .onDisappear(perform: onDisappear)
    }

    // MARK: - Subviews
    private var content: some View {
        VStack(spacing: 12) {
            header
            list
            footer
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var header: some View {
        HStack {
            Text(titleText).font(.headline)
            Spacer()
            Button("Done") { isPresented = false }
        }
        .padding(.horizontal)
    }

    private var list: some View {
        List(viewModel.items) { item in
            Text(item.title)
        }
        .listStyle(.plain)
    }

    private var footer: some View {
        HStack {
            Spacer()
            Button {
                withAnimation { isAnimating.toggle() }
            } label: {
                Label("Toggle", systemImage: isAnimating ? "pause.fill" : "play.fill")
            }
            Spacer()
        }
    }

    // MARK: - Actions
    private func onAppear() { viewModel.load() }
    private func onDisappear() { /* cleanup if needed */ }

    // MARK: - Nested Types (View-only helpers)
    private enum Local { static let padding: CGFloat = 8 }

    private struct Badge: View {
        let text: String
        var body: some View {
            Text(text)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Capsule())
        }
    }
}

// MARK: - Previews
#Preview {
    FeatureView(isPresented: .constant(true))
        .padding()
}
*/

// MARK: - PreferenceKey Example (Nested)
/*
import SwiftUI

struct ExampleView: View {
    // MARK: - Nested Types
    struct BarFrameKey: PreferenceKey {
        static var defaultValue: Anchor<CGRect>? = nil
        static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
            if let next = nextValue() { value = next }
        }
    }

    // MARK: - State
    @State private var barRect: CGRect = .zero

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .frame(height: 60)
                .anchorPreference(key: BarFrameKey.self, value: .bounds) { $0 }
        }
        .overlayPreferenceValue(BarFrameKey.self) { anchor in
            GeometryReader { proxy in
                Color.clear.onAppear {
                    if let anchor { barRect = proxy[anchor] }
                }
            }
        }
    }
}
*/

// MARK: - Composition Guidance
/*
 - Keep View light: push business logic to a ViewModel
 - Use dedicated subviews for complex UI blocks (private struct Subview: View)
 - Favor composition over conditionals inside body (extract branches into subviews)
 - Keep modifiers readable by grouping: frame → background → clipShape → overlay
*/

// MARK: - Access Control & Testing
/*
 - Prefer private for subviews and helpers
 - Use internal only when another file needs access
 - Keep #Preview simple; create preview data builders if needed
*/

// MARK: - Common MARK Tags (for Views)
/*
 // MARK: - Environment / Dependencies
 // MARK: - Bindings
 // MARK: - State
 // MARK: - Configuration
 // MARK: - Computed
 // MARK: - Init
 // MARK: - Body
 // MARK: - Subviews
 // MARK: - Actions
 // MARK: - Nested Types
 // MARK: - Previews
*/
