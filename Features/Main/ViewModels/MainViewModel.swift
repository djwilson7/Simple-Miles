import Foundation
import Combine
import SwiftUI

final class MainViewModel: ObservableObject {
    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()

    init() { }

    @MainActor func settingsTapped() {
        MainStateDriver.shared.mainState = .settings // when we click settings -> main state settings
    }

    func extendPauseTapped() {
        TravelStateManager.shared.extendPauseTimer()
    }
}
