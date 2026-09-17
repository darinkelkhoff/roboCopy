public final class AutoCopyCoordinator {
    private var recognizer: SelectionGestureRecognizer
    private let isEnabled: () -> Bool
    private let isAllowed: (AppIdentity) -> Bool
    private let dispatchCopy: (AppIdentity) -> Void

    public init(
        recognizer: SelectionGestureRecognizer = SelectionGestureRecognizer(),
        isEnabled: @escaping () -> Bool,
        isAllowed: @escaping (AppIdentity) -> Bool,
        dispatchCopy: @escaping (AppIdentity) -> Void
    ) {
        self.recognizer = recognizer
        self.isEnabled = isEnabled
        self.isAllowed = isAllowed
        self.dispatchCopy = dispatchCopy
    }

    public func handle(_ sample: MouseSample, frontmost: AppIdentity?) {
        guard let gesture = recognizer.consume(sample, target: frontmost) else { return }
        guard isEnabled(), isAllowed(gesture.target) else { return }

        dispatchCopy(gesture.target)
    }
}
