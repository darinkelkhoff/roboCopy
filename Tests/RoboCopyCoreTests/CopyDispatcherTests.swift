import Foundation
import XCTest
@testable import RoboCopyCore

final class CopyDispatcherTests: XCTestCase {
    private let target = AppIdentity(
        bundleIdentifier: "com.example.editor",
        displayName: "Editor"
    )

    func testDispatchSchedulesOnceAndPostsAfterRevalidatingMatchingBundleIdentifier() {
        var scheduledDelays: [TimeInterval] = []
        var scheduledAction: (() -> Void)?
        var postCount = 0
        let dispatcher = CopyDispatcher(
            isEnabled: { true },
            isTrusted: { true },
            frontmost: {
                AppIdentity(
                    bundleIdentifier: self.target.bundleIdentifier,
                    displayName: "Renamed Editor"
                )
            },
            schedule: { delay, action in
                scheduledDelays.append(delay)
                scheduledAction = action
            },
            postCommandC: { postCount += 1 }
        )

        dispatcher.dispatch(to: target)

        XCTAssertEqual(scheduledDelays, [0.04])
        XCTAssertEqual(postCount, 0)

        scheduledAction?()

        XCTAssertEqual(postCount, 1)
    }

    func testScheduledDispatchDoesNotPostWhenRevalidationFails() {
        let scenarios: [(
            name: String,
            isEnabled: Bool,
            isTrusted: Bool,
            frontmost: AppIdentity?
        )] = [
            ("disabled", false, true, target),
            ("untrusted", true, false, target),
            (
                "different bundle identifier",
                true,
                true,
                AppIdentity(bundleIdentifier: "com.example.other", displayName: "Editor")
            ),
            ("no frontmost application", true, true, nil),
        ]

        for scenario in scenarios {
            var scheduledAction: (() -> Void)?
            var postCount = 0
            let dispatcher = CopyDispatcher(
                isEnabled: { scenario.isEnabled },
                isTrusted: { scenario.isTrusted },
                frontmost: { scenario.frontmost },
                schedule: { _, action in scheduledAction = action },
                postCommandC: { postCount += 1 }
            )

            dispatcher.dispatch(to: target)
            scheduledAction?()

            XCTAssertEqual(postCount, 0, scenario.name)
        }
    }
}
