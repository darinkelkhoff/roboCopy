public struct ApplicationTarget: Equatable, Sendable {
    public let application: AppIdentity
    public let processIdentifier: Int32
    public let activationGeneration: UInt64

    public init(
        application: AppIdentity,
        processIdentifier: Int32,
        activationGeneration: UInt64
    ) {
        self.application = application
        self.processIdentifier = processIdentifier
        self.activationGeneration = activationGeneration
    }

    public static func == (lhs: ApplicationTarget, rhs: ApplicationTarget) -> Bool {
        lhs.application.bundleIdentifier == rhs.application.bundleIdentifier
            && lhs.processIdentifier == rhs.processIdentifier
            && lhs.activationGeneration == rhs.activationGeneration
    }
}
