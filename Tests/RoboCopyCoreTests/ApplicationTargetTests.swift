import XCTest
@testable import RoboCopyCore

final class ApplicationTargetTests: XCTestCase {
    func testEqualityUsesBundleIdentifierProcessAndGenerationButIgnoresDisplayName() {
        let original = ApplicationTarget(
            application: AppIdentity(
                bundleIdentifier: "com.example.editor",
                displayName: "Editor"
            ),
            processIdentifier: 101,
            activationGeneration: 7
        )
        let renamed = ApplicationTarget(
            application: AppIdentity(
                bundleIdentifier: "com.example.editor",
                displayName: "Renamed Editor"
            ),
            processIdentifier: 101,
            activationGeneration: 7
        )

        XCTAssertEqual(original, renamed)
        XCTAssertNotEqual(
            original,
            ApplicationTarget(
                application: original.application,
                processIdentifier: 102,
                activationGeneration: 7
            )
        )
        XCTAssertNotEqual(
            original,
            ApplicationTarget(
                application: original.application,
                processIdentifier: 101,
                activationGeneration: 8
            )
        )
    }
}
