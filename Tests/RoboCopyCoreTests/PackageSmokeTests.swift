import XCTest
@testable import RoboCopyCore

final class PackageSmokeTests: XCTestCase {
    func testAppIdentityStoresBundleMetadata() {
        let app = AppIdentity(bundleIdentifier: "com.example.Terminal", displayName: "Terminal")
        XCTAssertEqual(app.bundleIdentifier, "com.example.Terminal")
        XCTAssertEqual(app.displayName, "Terminal")
    }
}
