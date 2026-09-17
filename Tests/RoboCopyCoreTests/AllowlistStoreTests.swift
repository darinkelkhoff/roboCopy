import Foundation
import XCTest
@testable import RoboCopyCore

final class AllowlistStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "AllowlistStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testAddingAppPersistsAndReplacesDisplayNameForSameBundleIdentifier() {
        let store = AllowlistStore(defaults: defaults)
        let bundleIdentifier = "com.example.editor"

        store.add(AppIdentity(bundleIdentifier: bundleIdentifier, displayName: "Old Name"))
        store.add(AppIdentity(bundleIdentifier: bundleIdentifier, displayName: "Updated Name"))

        let reloadedStore = AllowlistStore(defaults: defaults)
        XCTAssertEqual(
            reloadedStore.apps,
            [AppIdentity(bundleIdentifier: bundleIdentifier, displayName: "Updated Name")]
        )
        XCTAssertTrue(reloadedStore.contains(bundleIdentifier: bundleIdentifier))
    }

    func testRemovingBundleIdentifierRemovesOnlyThatApp() {
        let store = AllowlistStore(defaults: defaults)
        let removedApp = AppIdentity(bundleIdentifier: "com.example.removed", displayName: "Removed")
        let retainedApp = AppIdentity(bundleIdentifier: "com.example.retained", displayName: "Retained")
        store.add(removedApp)
        store.add(retainedApp)

        store.remove(bundleIdentifier: removedApp.bundleIdentifier)

        let reloadedStore = AllowlistStore(defaults: defaults)
        XCTAssertEqual(reloadedStore.apps, [retainedApp])
        XCTAssertFalse(reloadedStore.contains(bundleIdentifier: removedApp.bundleIdentifier))
        XCTAssertTrue(reloadedStore.contains(bundleIdentifier: retainedApp.bundleIdentifier))
    }

    func testMalformedStoredDataLoadsAsEmptyAllowlist() {
        defaults.set(Data("not valid JSON".utf8), forKey: AllowlistStore.storageKey)

        let store = AllowlistStore(defaults: defaults)

        XCTAssertEqual(store.apps, [])
    }
}
