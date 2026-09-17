import Foundation
import XCTest
@testable import RoboCopyCore

final class CopyDispatcherTests: XCTestCase {
    private let target = ApplicationTarget(
        application: AppIdentity(
            bundleIdentifier: "com.example.editor",
            displayName: "Editor"
        ),
        processIdentifier: 101,
        activationGeneration: 7
    )

    func testDispatchPostsWhenOnlyDisplayNameChangesAfterScheduling() {
        var scheduledDelays: [TimeInterval] = []
        var scheduledAction: (() -> Void)?
        var enabledValidationCount = 0
        var trustValidationCount = 0
        var frontmostValidationCount = 0
        var postCount = 0
        let dispatcher = CopyDispatcher(
            isEnabled: {
                enabledValidationCount += 1
                return true
            },
            isTrusted: {
                trustValidationCount += 1
                return true
            },
            frontmost: {
                frontmostValidationCount += 1
                return ApplicationTarget(
                    application: AppIdentity(
                        bundleIdentifier: self.target.application.bundleIdentifier,
                        displayName: "Renamed Editor"
                    ),
                    processIdentifier: self.target.processIdentifier,
                    activationGeneration: self.target.activationGeneration
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
        XCTAssertEqual(enabledValidationCount, 0)
        XCTAssertEqual(trustValidationCount, 0)
        XCTAssertEqual(frontmostValidationCount, 0)

        scheduledAction?()

        XCTAssertEqual(postCount, 1)
        XCTAssertEqual(enabledValidationCount, 1)
        XCTAssertEqual(trustValidationCount, 1)
        XCTAssertEqual(frontmostValidationCount, 1)
    }

    func testScheduledDispatchDoesNotPostWhenRevalidationFails() {
        enum RevalidationFailure: String, CaseIterable {
            case disabled
            case untrusted
            case differentBundleIdentifier
            case differentProcessIdentifier
            case differentActivationGeneration
            case noFrontmostApplication
        }

        for scenario in RevalidationFailure.allCases {
            var isEnabled = true
            var isTrusted = true
            var frontmost: ApplicationTarget? = target
            var scheduledAction: (() -> Void)?
            var enabledValidationCount = 0
            var trustValidationCount = 0
            var frontmostValidationCount = 0
            var postCount = 0
            let dispatcher = CopyDispatcher(
                isEnabled: {
                    enabledValidationCount += 1
                    return isEnabled
                },
                isTrusted: {
                    trustValidationCount += 1
                    return isTrusted
                },
                frontmost: {
                    frontmostValidationCount += 1
                    return frontmost
                },
                schedule: { _, action in scheduledAction = action },
                postCommandC: { postCount += 1 }
            )

            dispatcher.dispatch(to: target)

            XCTAssertEqual(enabledValidationCount, 0, scenario.rawValue)
            XCTAssertEqual(trustValidationCount, 0, scenario.rawValue)
            XCTAssertEqual(frontmostValidationCount, 0, scenario.rawValue)

            switch scenario {
            case .disabled:
                isEnabled = false
            case .untrusted:
                isTrusted = false
            case .differentBundleIdentifier:
                frontmost = ApplicationTarget(
                    application: AppIdentity(
                        bundleIdentifier: "com.example.other",
                        displayName: "Editor"
                    ),
                    processIdentifier: target.processIdentifier,
                    activationGeneration: target.activationGeneration
                )
            case .differentProcessIdentifier:
                frontmost = ApplicationTarget(
                    application: target.application,
                    processIdentifier: target.processIdentifier + 1,
                    activationGeneration: target.activationGeneration
                )
            case .differentActivationGeneration:
                frontmost = ApplicationTarget(
                    application: target.application,
                    processIdentifier: target.processIdentifier,
                    activationGeneration: target.activationGeneration + 1
                )
            case .noFrontmostApplication:
                frontmost = nil
            }

            scheduledAction?()

            XCTAssertEqual(postCount, 0, scenario.rawValue)
        }
    }

    func testScheduledActionDoesNotRetainDispatcher() {
        var scheduledAction: (() -> Void)?
        var postCount = 0
        var dispatcher: CopyDispatcher? = CopyDispatcher(
            isEnabled: { true },
            isTrusted: { true },
            frontmost: { self.target },
            schedule: { _, action in scheduledAction = action },
            postCommandC: { postCount += 1 }
        )
        weak let weakDispatcher = dispatcher

        dispatcher?.dispatch(to: target)
        dispatcher = nil

        XCTAssertNil(weakDispatcher)

        scheduledAction?()

        XCTAssertEqual(postCount, 1)
    }
}
