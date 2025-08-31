import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()
    private var cancellables = Set<AnyCancellable>()
    @Published var pages: [SettingsPage] = [.account, .display, .tracking]
    @Published var currentIndex: Int = 0
    
}
