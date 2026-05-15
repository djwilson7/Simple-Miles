import Testing
@testable import SimpleMilesBackEnd
import Foundation
import CoreLocation

@Suite("ArrowHeadingManager Tests")
struct ArrowHeadingManagerTests {
    
    @MainActor
    @Test("Rotation modes details")
    func testDetailedRotation() {
        let manager = ArrowHeadingManager.shared

        // Heads Up
        manager.updateArrowRotation(cameraHeading: 0, trueHeading: 90, mapHeading: 0, orientation: .headingUp)
        #expect(manager.desiredArrowRotation == 0)

        // North Up
        manager.updateArrowRotation(cameraHeading: 0, trueHeading: 45, mapHeading: 0, orientation: .northUp)
        #expect(manager.desiredArrowRotation == 45)

        // Free Roam
        manager.updateArrowRotation(cameraHeading: 0, trueHeading: 90, mapHeading: 10, orientation: .freeRoam)
        #expect(manager.desiredArrowRotation == 80)

        // Reviewing (North Up)
        CameraManager.shared.lastNonFreeRoamOrientation = .northUp
        manager.updateArrowRotation(cameraHeading: 0, trueHeading: 100, mapHeading: 0, orientation: .reviewing)
        #expect(manager.desiredArrowRotation == 100)

        // Reviewing (Heading Up)
        CameraManager.shared.lastNonFreeRoamOrientation = .headingUp
        manager.updateArrowRotation(cameraHeading: 0, trueHeading: 100, mapHeading: 0, orientation: .reviewing)
        #expect(manager.desiredArrowRotation == 0)
    }

    @MainActor
    @Test("Smooth angle transition wrap negative")
    func testSmoothingNegative() {
        let manager = ArrowHeadingManager.shared

        // Wrap around 0 (delta < -180)
        manager.desiredArrowRotation = 10
        manager.updateArrowRotation(cameraHeading: 0, trueHeading: 350, mapHeading: 0, orientation: .northUp)
        // 350 - 10 = 340. abs(340) > 180. delta > 0. return old - (360 - delta) = 10 - (360 - 340) = -10
        #expect(manager.desiredArrowRotation == -10)
    }}
