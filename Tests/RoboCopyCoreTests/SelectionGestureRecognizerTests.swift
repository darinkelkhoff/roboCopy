import Foundation
import XCTest
@testable import RoboCopyCore

final class SelectionGestureRecognizerTests: XCTestCase {
    private let target = AppIdentity(
        bundleIdentifier: "com.example.editor",
        displayName: "Editor"
    )

    func testDragAtThresholdRetainsMouseDownTargetAndModifiers() {
        var recognizer = SelectionGestureRecognizer()
        let mouseDownModifiers: UInt = 1 << 20

        XCTAssertNil(recognizer.consume(
            .down(at: CGPoint(x: 1, y: 2), clickCount: 1, modifiers: mouseDownModifiers),
            target: target
        ))

        let gesture = recognizer.consume(
            .up(at: CGPoint(x: 5, y: 2), clickCount: 1, modifiers: 0),
            target: AppIdentity(
                bundleIdentifier: target.bundleIdentifier,
                displayName: "Renamed Editor"
            )
        )

        XCTAssertEqual(gesture, SelectionGesture(
            target: target,
            kind: .drag,
            modifiers: mouseDownModifiers
        ))
    }

    func testDragBelowThresholdDoesNotQualify() {
        var recognizer = SelectionGestureRecognizer()

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 1, modifiers: 0),
            target: target
        ))

        XCTAssertNil(recognizer.consume(
            .up(at: CGPoint(x: 3.99, y: 0), clickCount: 1, modifiers: 0),
            target: target
        ))
    }

    func testDoubleClickAndTripleClickQualifyAsMultiClick() {
        for clickCount in [2, 3] {
            var recognizer = SelectionGestureRecognizer()

            XCTAssertNil(recognizer.consume(
                .down(at: .zero, clickCount: clickCount, modifiers: 0),
                target: target
            ))

            XCTAssertEqual(
                recognizer.consume(
                    .up(at: .zero, clickCount: clickCount, modifiers: 0),
                    target: target
                ),
                SelectionGesture(target: target, kind: .multiClick, modifiers: 0)
            )
        }
    }

    func testOrdinarySingleClickDoesNotQualify() {
        var recognizer = SelectionGestureRecognizer()

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 1, modifiers: 0),
            target: target
        ))

        XCTAssertNil(recognizer.consume(
            .up(at: .zero, clickCount: 1, modifiers: 0),
            target: target
        ))
    }

    func testGestureIsCanceledWhenMouseUpBundleIdentifierDiffers() {
        var recognizer = SelectionGestureRecognizer()

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 2, modifiers: 0),
            target: target
        ))

        XCTAssertNil(recognizer.consume(
            .up(at: CGPoint(x: 10, y: 0), clickCount: 2, modifiers: 0),
            target: AppIdentity(
                bundleIdentifier: "com.example.other",
                displayName: "Other"
            )
        ))
    }
}
