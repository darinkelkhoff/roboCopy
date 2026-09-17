import Foundation

public final class AllowlistStore {
    public static let storageKey = "allowedApplications"

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var storedApps: [AppIdentity]

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Self.storageKey),
           let apps = try? decoder.decode([AppIdentity].self, from: data) {
            storedApps = apps
        } else {
            storedApps = []
        }
    }

    public var apps: [AppIdentity] {
        storedApps.sorted {
            let displayNameOrder = $0.displayName.caseInsensitiveCompare($1.displayName)
            if displayNameOrder == .orderedSame {
                return $0.bundleIdentifier < $1.bundleIdentifier
            }
            return displayNameOrder == .orderedAscending
        }
    }

    public func contains(bundleIdentifier: String) -> Bool {
        storedApps.contains { $0.bundleIdentifier == bundleIdentifier }
    }

    public func add(_ app: AppIdentity) {
        storedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
        storedApps.append(app)
        persist()
    }

    public func remove(bundleIdentifier: String) {
        storedApps.removeAll { $0.bundleIdentifier == bundleIdentifier }
        persist()
    }

    private func persist() {
        guard let data = try? encoder.encode(storedApps) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }
}
