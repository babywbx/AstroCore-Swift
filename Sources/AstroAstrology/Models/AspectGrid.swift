import AstroCore

public struct AspectGrid: Sendable, Equatable, Codable {
    /// Participating bodies in CaseIterable order; defines the matrix axes.
    public let bodies: [CelestialBody]
    /// Matched aspects only, upper-triangular and deduplicated.
    public let aspects: [Aspect]

    public init(bodies: [CelestialBody], aspects: [Aspect]) {
        self.bodies = bodies
        self.aspects = aspects
    }

    /// Aspect between a pair regardless of argument order.
    public func aspect(between a: CelestialBody, and b: CelestialBody) -> Aspect? {
        aspects.first {
            ($0.bodyA == a && $0.bodyB == b) || ($0.bodyA == b && $0.bodyB == a)
        }
    }

    public func aspects(of body: CelestialBody) -> [Aspect] {
        aspects.filter { $0.bodyA == body || $0.bodyB == body }
    }
}
