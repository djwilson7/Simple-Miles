//
//  DataPrivacyPermissions.swift
//  SimpleMiles
//
//  Created by Invictus Maneo on 7/14/25.
//

import XCTest
import Combine
@testable import SimpleMiles

final class DataPrivacyPermissionsTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    func testLoadsDefaultFromStore() {
        let store = MockSettingsStore()
        let permissions = DataPrivacyPermissions(store: store)
        XCTAssertEqual(permissions.consentLevel, .none)
    }

    func testPersistsChangesToStore() {
        let store = MockSettingsStore()
        let permissions = DataPrivacyPermissions(store: store)
        permissions.consentLevel = .fullSharing

        let result: PrivacyConsentLevel = store.getEnum(.privacyConsentLevel, default: .none)
        XCTAssertEqual(result, .fullSharing)
    }

    func testPublishesOnChange() {
        let store = MockSettingsStore()
        let permissions = DataPrivacyPermissions(store: store)
        let expectation = expectation(description: "Change should publish")

        permissions.objectWillChange
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        permissions.consentLevel = .diagnostics
        wait(for: [expectation], timeout: 0.2)
    }
}
