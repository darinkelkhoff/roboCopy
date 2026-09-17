import Foundation

public enum MouseSample: Equatable {
    case down(at: CGPoint, clickCount: Int, modifiers: UInt)
    case dragged(to: CGPoint, modifiers: UInt)
    case up(at: CGPoint, clickCount: Int, modifiers: UInt)

    public static func == (lhs: MouseSample, rhs: MouseSample) -> Bool {
        switch (lhs, rhs) {
        case let (.down(lhsPoint, lhsCount, lhsModifiers),
                  .down(rhsPoint, rhsCount, rhsModifiers)),
             let (.up(lhsPoint, lhsCount, lhsModifiers),
                  .up(rhsPoint, rhsCount, rhsModifiers)):
            return pointsEqual(lhsPoint, rhsPoint)
                && lhsCount == rhsCount
                && lhsModifiers == rhsModifiers

        case let (.dragged(lhsPoint, lhsModifiers),
                  .dragged(rhsPoint, rhsModifiers)):
            return pointsEqual(lhsPoint, rhsPoint)
                && lhsModifiers == rhsModifiers

        default:
            return false
        }
    }

    private static func pointsEqual(_ lhs: CGPoint, _ rhs: CGPoint) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y
    }
}

public struct SelectionGesture: Equatable {
    public enum Kind: Equatable {
        case drag
        case multiClick
    }

    public let target: AppIdentity
    public let kind: Kind
    public let modifiers: UInt

    public init(target: AppIdentity, kind: Kind, modifiers: UInt) {
        self.target = target
        self.kind = kind
        self.modifiers = modifiers
    }
}

public struct SelectionGestureRecognizer {
    private struct State {
        let origin: CGPoint
        let initialClickCount: Int
        let initialModifiers: UInt
        let initialTarget: AppIdentity
        var farthestDistance: CGFloat
    }

    private let dragThreshold: CGFloat
    private var state: State?

    public init(dragThreshold: CGFloat = 4) {
        self.dragThreshold = dragThreshold
    }

    public mutating func consume(
        _ sample: MouseSample,
        target: AppIdentity?
    ) -> SelectionGesture? {
        switch sample {
        case let .down(origin, clickCount, modifiers):
            guard let target else {
                state = nil
                return nil
            }

            state = State(
                origin: origin,
                initialClickCount: clickCount,
                initialModifiers: modifiers,
                initialTarget: target,
                farthestDistance: 0
            )
            return nil

        case let .dragged(point, _):
            updateFarthestDistance(to: point)
            return nil

        case let .up(point, clickCount, _):
            guard var completedState = state else { return nil }
            state = nil

            guard target?.bundleIdentifier == completedState.initialTarget.bundleIdentifier else {
                return nil
            }

            completedState.farthestDistance = max(
                completedState.farthestDistance,
                distance(from: completedState.origin, to: point)
            )

            let kind: SelectionGesture.Kind
            if completedState.farthestDistance >= dragThreshold {
                kind = .drag
            } else if max(completedState.initialClickCount, clickCount) >= 2 {
                kind = .multiClick
            } else {
                return nil
            }

            return SelectionGesture(
                target: completedState.initialTarget,
                kind: kind,
                modifiers: completedState.initialModifiers
            )
        }
    }

    private mutating func updateFarthestDistance(to point: CGPoint) {
        guard var state else { return }
        state.farthestDistance = max(
            state.farthestDistance,
            distance(from: state.origin, to: point)
        )
        self.state = state
    }

    private func distance(from origin: CGPoint, to point: CGPoint) -> CGFloat {
        hypot(point.x - origin.x, point.y - origin.y)
    }
}
