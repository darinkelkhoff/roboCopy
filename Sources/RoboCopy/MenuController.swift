import AppKit
import RoboCopyCore
import ServiceManagement

final class MenuController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let defaults: UserDefaults
    private let allowlist: AllowlistStore
    private let tracker: FrontmostApplicationTracker
    private let accessibility: AccessibilityController
    private let launchAtLogin: LaunchAtLoginController
    private var launchAtLoginError: String?

    init(
        defaults: UserDefaults,
        allowlist: AllowlistStore,
        tracker: FrontmostApplicationTracker,
        accessibility: AccessibilityController,
        launchAtLogin: LaunchAtLoginController
    ) {
        self.defaults = defaults
        self.allowlist = allowlist
        self.tracker = tracker
        self.accessibility = accessibility
        self.launchAtLogin = launchAtLogin
        super.init()

        statusItem.button?.image = Self.statusImage()
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    private static func statusImage() -> NSImage? {
        guard let url = Bundle.main.url(
            forResource: "MenuBarIconTemplate",
            withExtension: "png"
        ), let image = NSImage(contentsOf: url) else {
            return NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "RoboCopy"
            )
        }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        image.accessibilityDescription = "RoboCopy"
        return image
    }

    var isEnabled: Bool {
        get { defaults.object(forKey: "isEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "isEnabled") }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(item("Enabled", action: #selector(toggleEnabled), state: isEnabled))
        menu.addItem(.separator())

        if let app = tracker.lastExternalApplication {
            let currentAppItem = item(
                "Auto-copy in \(app.displayName)",
                action: #selector(toggleCurrentApp(_:)),
                state: allowlist.contains(bundleIdentifier: app.bundleIdentifier)
            )
            currentAppItem.representedObject = app
            menu.addItem(currentAppItem)
        } else if let name = tracker.unsupportedApplicationName {
            let unavailable = NSMenuItem(
                title: "\(name) cannot be added (no bundle ID)",
                action: nil,
                keyEquivalent: ""
            )
            unavailable.isEnabled = false
            menu.addItem(unavailable)
        } else {
            let unavailable = NSMenuItem(
                title: "No recent application",
                action: nil,
                keyEquivalent: ""
            )
            unavailable.isEnabled = false
            menu.addItem(unavailable)
        }

        let allowedItem = NSMenuItem(title: "Allowed Apps", action: nil, keyEquivalent: "")
        let allowedMenu = NSMenu()
        if allowlist.apps.isEmpty {
            let empty = NSMenuItem(title: "None", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            allowedMenu.addItem(empty)
        } else {
            for app in allowlist.apps {
                let remove = item(
                    app.displayName,
                    action: #selector(removeAllowedApp(_:)),
                    state: true
                )
                remove.representedObject = app.bundleIdentifier
                allowedMenu.addItem(remove)
            }
        }
        allowedItem.submenu = allowedMenu
        menu.addItem(allowedItem)

        menu.addItem(.separator())
        if accessibility.isTrusted {
            let granted = NSMenuItem(
                title: "Accessibility: Granted",
                action: nil,
                keyEquivalent: ""
            )
            granted.isEnabled = false
            menu.addItem(granted)
        } else {
            menu.addItem(
                item(
                    "Grant Accessibility Access...",
                    action: #selector(openAccessibilitySettings)
                )
            )
        }

        menu.addItem(
            item(
                "Launch at Login",
                action: #selector(toggleLaunchAtLogin),
                state: launchAtLogin.isEnabled
            )
        )
        if let launchAtLoginError {
            let error = NSMenuItem(
                title: "Launch at Login Error: \(launchAtLoginError)",
                action: nil,
                keyEquivalent: ""
            )
            error.isEnabled = false
            menu.addItem(error)
        }
        if launchAtLogin.status == .requiresApproval {
            menu.addItem(
                item(
                    "Approve Launch at Login...",
                    action: #selector(openLaunchAtLoginSettings)
                )
            )
        }

        menu.addItem(.separator())
        menu.addItem(item("Quit RoboCopy", action: #selector(quit)))
    }

    private func item(_ title: String, action: Selector, state: Bool? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        if let state {
            item.state = state ? .on : .off
        }
        return item
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
    }

    @objc private func toggleCurrentApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? AppIdentity else { return }

        if allowlist.contains(bundleIdentifier: app.bundleIdentifier) {
            allowlist.remove(bundleIdentifier: app.bundleIdentifier)
        } else {
            allowlist.add(app)
        }
    }

    @objc private func removeAllowedApp(_ sender: NSMenuItem) {
        guard let bundleIdentifier = sender.representedObject as? String else { return }
        allowlist.remove(bundleIdentifier: bundleIdentifier)
    }

    @objc private func openAccessibilitySettings() {
        accessibility.requestAccess()
        accessibility.openSettings()
    }

    @objc private func toggleLaunchAtLogin() {
        launchAtLoginError = nil
        do {
            try launchAtLogin.setEnabled(!launchAtLogin.isEnabled)
        } catch {
            launchAtLoginError = error.localizedDescription
        }
    }

    @objc private func openLaunchAtLoginSettings() {
        launchAtLogin.openSettings()
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
