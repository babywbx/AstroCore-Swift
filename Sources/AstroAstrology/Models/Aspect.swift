import AstroCore

public struct Aspect: Sendable, Hashable, Codable {
    /// Canonical order: by CelestialBody CaseIterable position (bodyA before bodyB).
    public let bodyA: CelestialBody
    public let bodyB: CelestialBody
    public let kind: AspectKind
    /// Signed deviation = separation − aspectAngle (deg), in (-allowedOrb, allowedOrb).
    public let deviation: Double
    /// Allowed orb that admitted this aspect (the spoken "orb").
    public let allowedOrb: Double
    /// Applying (true) / separating (false); endpoints always carry speed, hence non-optional.
    public let isApplying: Bool
    /// |deviation| within the partile threshold.
    public let isExact: Bool

    public var isSeparating: Bool { !isApplying }

    public init(
        bodyA: CelestialBody,
        bodyB: CelestialBody,
        kind: AspectKind,
        deviation: Double,
        allowedOrb: Double,
        isApplying: Bool,
        isExact: Bool
    ) {
        self.bodyA = bodyA
        self.bodyB = bodyB
        self.kind = kind
        self.deviation = deviation
        self.allowedOrb = allowedOrb
        self.isApplying = isApplying
        self.isExact = isExact
    }
}
