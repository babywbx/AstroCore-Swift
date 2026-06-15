import AstroCore

extension AstrologyCalculator {
    /// Single-pair aspect query; nil when the separation exceeds every kind's allowed orb.
    public static func aspect(
        between bodyA: CelestialBody,
        and bodyB: CelestialBody,
        for moment: CivilMoment,
        aspectKinds: Set<AspectKind> = AspectKind.ptolemaic,
        orbPolicy: OrbPolicy = .default
    ) throws(AstrologyError) -> Aspect? {
        guard bodyA != bodyB else { return nil }
        let states = AstroCalculator.states(of: [bodyA, bodyB], at: moment)
        guard let stateA = states[bodyA], let stateB = states[bodyB] else { return nil }
        return AspectEngine.resolve(
            stateA, stateB, aspectKinds: aspectKinds, orbPolicy: orbPolicy
        )
    }
}
