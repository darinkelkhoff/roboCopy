import AppKit
import RoboCopyCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var tracker: FrontmostApplicationTracker!
    private var mouseMonitor: GlobalMouseMonitor!
    private var menuController: MenuController!
    private var coordinator: AutoCopyCoordinator!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let defaults = UserDefaults.standard
        let allowlist = AllowlistStore(defaults: defaults)
        let accessibility = AccessibilityController()
        let launchAtLogin = LaunchAtLoginController()
        let commandCPoster = CommandCPoster()

        tracker = FrontmostApplicationTracker()
        menuController = MenuController(
            defaults: defaults,
            allowlist: allowlist,
            tracker: tracker,
            accessibility: accessibility,
            launchAtLogin: launchAtLogin
        )

        let dispatcher = CopyDispatcher(
            isEnabled: { [weak menuController] in
                menuController?.isEnabled ?? false
            },
            isTrusted: { [weak accessibility] in
                accessibility?.isTrusted ?? false
            },
            frontmost: { [weak tracker] in
                tracker?.frontmostApplication
            },
            schedule: { delay, action in
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + delay,
                    execute: action
                )
            },
            postCommandC: {
                commandCPoster.post()
            }
        )

        coordinator = AutoCopyCoordinator(
            isEnabled: { [weak menuController] in
                menuController?.isEnabled ?? false
            },
            isAllowed: { [weak allowlist] app in
                allowlist?.contains(bundleIdentifier: app.bundleIdentifier) ?? false
            },
            dispatchCopy: { target in
                dispatcher.dispatch(to: target)
            }
        )

        mouseMonitor = GlobalMouseMonitor()
        mouseMonitor.start { [weak self] sample in
            guard let self else { return }
            self.coordinator.handle(sample, frontmost: self.tracker.frontmostApplication)
        }

        accessibility.requestAccess()
    }
}
