public final class AutoCopyCoordinator {
    private var recognizer: SelectionGestureRecognizer
    private let isEnabled: () -> Bool
    private let isAllowed: (AppIdentity) -> Bool
    private let dispatchCopy: (ApplicationTarget) -> Void

    public init(
        recognizer: SelectionGestureRecognizer = SelectionGestureRecognizer(),
        isEnabled: @escaping () -> Bool,
        isAllowed: @escaping (AppIdentity) -> Bool,
        dispatchCopy: @escaping (ApplicationTarget) -> Void
    ) {
        self.recognizer = recognizer
        self.isEnabled = isEnabled
        self.isAllowed = isAllowed
        self.dispatchCopy = dispatchCopy
    }

    public func handle(_ sample: MouseSample, frontmost: ApplicationTarget?) {
        guard let gesture = recognizer.consume(sample, target: frontmost) else { return }
        guard isEnabled(), isAllowed(gesture.target.application) else { return }

        dispatchCopy(gesture.target)
    }
}
