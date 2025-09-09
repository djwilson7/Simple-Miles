import Foundation
import SwiftUI

/// Minimal view model for SettingsView: holds the static pages list and the current page index.
/// The view drives paging (swipe/indicators) by binding to `currentIndex`.
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Singleton
    static let shared = SettingsViewModel()

    // MARK: - Published State (UI)
    /// The currently selected page index (bound by SettingsView's TabView and indicators).
    @Published var currentIndex: Int = 0

    // MARK: - Configuration (Static)
    /// The ordered list of settings pages rendered by SettingsView.
    let pages: [SettingsPage] = [.account, .display, .tracking]

    // MARK: - Init
    private init() { }
}
