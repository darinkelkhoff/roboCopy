import ServiceManagement

final class LaunchAtLoginController {
    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    var isEnabled: Bool {
        switch status {
        case .enabled, .requiresApproval:
            true
        case .notRegistered, .notFound:
            false
        @unknown default:
            false
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        switch (enabled, status) {
        case (true, .notRegistered), (true, .notFound):
            try SMAppService.mainApp.register()
        case (false, .enabled), (false, .requiresApproval):
            try SMAppService.mainApp.unregister()
        case (true, .enabled), (true, .requiresApproval),
             (false, .notRegistered), (false, .notFound):
            break
        @unknown default:
            break
        }
    }

    func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
