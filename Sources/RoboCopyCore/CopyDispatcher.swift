import Foundation

public final class CopyDispatcher {
    public typealias Scheduler = (TimeInterval, @escaping () -> Void) -> Void

    private let isEnabled: () -> Bool
    private let isTrusted: () -> Bool
    private let frontmost: () -> AppIdentity?
    private let schedule: Scheduler
    private let postCommandC: () -> Void

    public init(
        isEnabled: @escaping () -> Bool,
        isTrusted: @escaping () -> Bool,
        frontmost: @escaping () -> AppIdentity?,
        schedule: @escaping Scheduler,
        postCommandC: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.isTrusted = isTrusted
        self.frontmost = frontmost
        self.schedule = schedule
        self.postCommandC = postCommandC
    }

    public func dispatch(to target: AppIdentity) {
        schedule(0.04) { [isEnabled, isTrusted, frontmost, postCommandC] in
            guard isEnabled(), isTrusted() else { return }
            guard frontmost()?.bundleIdentifier == target.bundleIdentifier else { return }

            postCommandC()
        }
    }
}
