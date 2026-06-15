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

    /// All matched aspects (upper-triangular, deduplicated) among a set of bodies at a moment.
    public static func aspects(
        for moment: CivilMoment,
        bodies: Set<CelestialBody>,
        aspectKinds: Set<AspectKind> = AspectKind.ptolemaic,
        orbPolicy: OrbPolicy = .default
    ) throws(AstrologyError) -> AspectGrid {
        AspectEngine.gridAspects(
            for: moment,
            bodies: bodies,
            aspectKinds: aspectKinds,
            orbPolicy: orbPolicy,
            statesProvider: AstroCalculator.states(of:at:)
        ).grid
    }

    /// Aspects computed directly from already-resolved motion-rich states (no re-ephemeris).
    public static func aspects(
        among states: [CelestialBody: CelestialState],
        aspectKinds: Set<AspectKind> = AspectKind.ptolemaic,
        orbPolicy: OrbPolicy = .default
    ) -> AspectGrid {
        AspectEngine.buildGrid(
            among: states, aspectKinds: aspectKinds, orbPolicy: orbPolicy
        ).grid
    }
}
