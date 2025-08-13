import Foundation
import Combine
import SwiftUI

final class MainViewModel: ObservableObject {
    // MARK: - Internal

    private var cancellables = Set<AnyCancellable>()

    init() { }

    
    func settingsTapped() {
        MainStateDriver.shared.mainState = .settings // when we click settings -> main state settings
    }
    
    func summaryTapped()  {
        MainStateDriver.shared.mainState = .review // when we click summary -> we set main state to review
    }

    func extendPauseTapped() {
        TravelStateManager.shared.extendPauseTimer()
    }
}
