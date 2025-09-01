import Combine
import Foundation
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()
    private var cancellables = Set<AnyCancellable>()
    @Published var pages: [SettingsPage] = [.account, .display, .tracking]
    @Published var currentIndex: Int = 0

}
