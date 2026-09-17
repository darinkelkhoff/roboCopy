import AppKit
import ApplicationServices
import CoreGraphics
import RoboCopyCore

final class FrontmostApplicationTracker {
    private(set) var lastExternalApplication: AppIdentity?
    private(set) var unsupportedApplicationName: String?

    private let ownProcessIdentifier = ProcessInfo.processInfo.processIdentifier
    private let workspace: NSWorkspace
    private var observer: NSObjectProtocol?

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
        update(from: workspace.frontmostApplication)
        observer = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.update(
                from: notification.userInfo?[NSWorkspace.applicationUserInfoKey]
                    as? NSRunningApplication
            )
        }
    }

    deinit {
        if let observer {
            workspace.notificationCenter.removeObserver(observer)
        }
    }

    var frontmostApplication: AppIdentity? {
        identity(for: workspace.frontmostApplication)
    }

    private func update(from application: NSRunningApplication?) {
        guard let application,
              application.processIdentifier != ownProcessIdentifier else { return }

        if let identity = identity(for: application) {
            lastExternalApplication = identity
            unsupportedApplicationName = nil
        } else {
            lastExternalApplication = nil
            unsupportedApplicationName = application.localizedName ?? "This application"
        }
    }

    private func identity(for application: NSRunningApplication?) -> AppIdentity? {
        guard let application,
              application.processIdentifier != ownProcessIdentifier,
              let bundleIdentifier = application.bundleIdentifier else { return nil }

        return AppIdentity(
            bundleIdentifier: bundleIdentifier,
            displayName: application.localizedName ?? bundleIdentifier
        )
    }
}

final class AccessibilityController {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestAccess() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true,
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    func openSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }

        NSWorkspace.shared.open(url)
    }
}

final class CommandCPoster {
    func post() {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: 8,
                  keyDown: true
              ),
              let keyUp = CGEvent(
                  keyboardEventSource: source,
                  virtualKey: 8,
                  keyDown: false
              ) else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}

final class GlobalMouseMonitor {
    private var token: Any?

    func start(handler: @escaping (MouseSample) -> Void) {
        stop()
        token = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseDragged, .leftMouseUp]
        ) { event in
            let point = event.locationInWindow
            let modifiers = event.modifierFlags.rawValue

            switch event.type {
            case .leftMouseDown:
                handler(.down(at: point, clickCount: event.clickCount, modifiers: modifiers))
            case .leftMouseDragged:
                handler(.dragged(to: point, modifiers: modifiers))
            case .leftMouseUp:
                handler(.up(at: point, clickCount: event.clickCount, modifiers: modifiers))
            default:
                break
            }
        }
    }

    func stop() {
        guard let token else { return }
        NSEvent.removeMonitor(token)
        self.token = nil
    }

    deinit {
        stop()
    }
}
