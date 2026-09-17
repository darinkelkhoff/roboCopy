import Foundation
import XCTest
@testable import RoboCopyCore

final class SelectionGestureRecognizerTests: XCTestCase {
    private let target = ApplicationTarget(
        application: AppIdentity(
            bundleIdentifier: "com.example.editor",
            displayName: "Editor"
        ),
        processIdentifier: 101,
        activationGeneration: 7
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
            target: ApplicationTarget(
                application: AppIdentity(
                    bundleIdentifier: target.application.bundleIdentifier,
                    displayName: "Renamed Editor"
                ),
                processIdentifier: target.processIdentifier,
                activationGeneration: target.activationGeneration
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

    func testGestureIsCanceledWhenMouseUpRuntimeTargetDiffers() {
        var recognizer = SelectionGestureRecognizer()

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 2, modifiers: 0),
            target: target
        ))

        XCTAssertNil(recognizer.consume(
            .up(at: CGPoint(x: 10, y: 0), clickCount: 2, modifiers: 0),
            target: ApplicationTarget(
                application: AppIdentity(
                    bundleIdentifier: "com.example.other",
                    displayName: "Other"
                ),
                processIdentifier: 202,
                activationGeneration: 8
            )
        ))
    }

    func testGestureStaysCanceledAfterDraggedTargetDiffers() {
        var recognizer = SelectionGestureRecognizer()
        let otherTarget = ApplicationTarget(
            application: AppIdentity(
                bundleIdentifier: "com.example.other",
                displayName: "Other"
            ),
            processIdentifier: 202,
            activationGeneration: 8
        )

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 1, modifiers: 0),
            target: target
        ))
        XCTAssertNil(recognizer.consume(
            .dragged(to: CGPoint(x: 5, y: 0), modifiers: 0),
            target: otherTarget
        ))

        XCTAssertNil(recognizer.consume(
            .up(at: CGPoint(x: 5, y: 0), clickCount: 1, modifiers: 0),
            target: target
        ))
    }

    func testSameBundleWithDifferentProcessDuringDragPermanentlyCancels() {
        var recognizer = SelectionGestureRecognizer()
        let replacementProcess = ApplicationTarget(
            application: target.application,
            processIdentifier: target.processIdentifier + 1,
            activationGeneration: target.activationGeneration
        )

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 1, modifiers: 0),
            target: target
        ))
        XCTAssertNil(recognizer.consume(
            .dragged(to: CGPoint(x: 5, y: 0), modifiers: 0),
            target: replacementProcess
        ))
        XCTAssertNil(recognizer.consume(
            .up(at: CGPoint(x: 5, y: 0), clickCount: 1, modifiers: 0),
            target: target
        ))
    }

    func testSameApplicationAndProcessWithDifferentGenerationCancels() {
        var recognizer = SelectionGestureRecognizer()
        let reactivatedTarget = ApplicationTarget(
            application: target.application,
            processIdentifier: target.processIdentifier,
            activationGeneration: target.activationGeneration + 1
        )

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 2, modifiers: 0),
            target: target
        ))
        XCTAssertNil(recognizer.consume(
            .up(at: .zero, clickCount: 2, modifiers: 0),
            target: reactivatedTarget
        ))
    }

    func testExactRuntimeTargetSucceeds() {
        var recognizer = SelectionGestureRecognizer()

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 2, modifiers: 0),
            target: target
        ))
        XCTAssertEqual(
            recognizer.consume(
                .up(at: .zero, clickCount: 2, modifiers: 0),
                target: target
            ),
            SelectionGesture(target: target, kind: .multiClick, modifiers: 0)
        )
    }

    func testDragUsesFarthestDistanceWhenMouseReturnsNearOrigin() {
        var recognizer = SelectionGestureRecognizer()

        XCTAssertNil(recognizer.consume(
            .down(at: .zero, clickCount: 1, modifiers: 0),
            target: target
        ))
        XCTAssertNil(recognizer.consume(
            .dragged(to: CGPoint(x: 5, y: 0), modifiers: 0),
            target: target
        ))

        XCTAssertEqual(
            recognizer.consume(
                .up(at: CGPoint(x: 1, y: 0), clickCount: 1, modifiers: 0),
                target: target
            ),
            SelectionGesture(target: target, kind: .drag, modifiers: 0)
        )
    }
}
