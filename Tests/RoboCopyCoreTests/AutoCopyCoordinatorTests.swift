import Foundation
import XCTest
@testable import RoboCopyCore

final class AutoCopyCoordinatorTests: XCTestCase {
    private let target = ApplicationTarget(
        application: AppIdentity(
            bundleIdentifier: "com.example.editor",
            displayName: "Editor"
        ),
        processIdentifier: 101,
        activationGeneration: 7
    )

    func testQualifyingDragInAllowedAppWhileEnabledDispatchesTargetOnce() {
        var dispatchedTargets: [ApplicationTarget] = []
        let coordinator = AutoCopyCoordinator(
            isEnabled: { true },
            isAllowed: { $0.bundleIdentifier == self.target.application.bundleIdentifier },
            dispatchCopy: { dispatchedTargets.append($0) }
        )

        performQualifyingDrag(with: coordinator)

        XCTAssertEqual(dispatchedTargets, [target])
    }

    func testQualifyingDragDoesNotDispatchWhenDisabledOrBlocked() {
        let scenarios: [(isEnabled: Bool, isAllowed: Bool)] = [
            (isEnabled: false, isAllowed: true),
            (isEnabled: true, isAllowed: false),
        ]

        for scenario in scenarios {
            var dispatchedTargets: [ApplicationTarget] = []
            let coordinator = AutoCopyCoordinator(
                isEnabled: { scenario.isEnabled },
                isAllowed: { _ in scenario.isAllowed },
                dispatchCopy: { dispatchedTargets.append($0) }
            )

            performQualifyingDrag(with: coordinator)

            XCTAssertEqual(dispatchedTargets, [])
        }
    }

    private func performQualifyingDrag(with coordinator: AutoCopyCoordinator) {
        coordinator.handle(
            .down(at: .zero, clickCount: 1, modifiers: 0),
            frontmost: target
        )
        coordinator.handle(
            .up(at: CGPoint(x: 5, y: 0), clickCount: 1, modifiers: 0),
            frontmost: target
        )
    }
}
