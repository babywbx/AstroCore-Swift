import AstroCore

extension AstrologyCalculator {
    /// Aspect patterns (stellium, grand trine, T-square, …) recognised on an existing grid.
    /// Pure combinatorial detection over the grid edges; no ephemeris.
    public static func patterns(in grid: AspectGrid) -> [AspectPattern] {
        AspectPatternDetector.patterns(in: grid)
    }

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

    /// Synastry / transit cross-set aspects: every natal body against every transit body.
    /// Applying uses both states' speeds (relSpeed = transit − natal).
    public static func crossAspects(
        natal natalStates: [CelestialBody: CelestialState],
        transit transitStates: [CelestialBody: CelestialState],
        aspectKinds: Set<AspectKind> = AspectKind.ptolemaic,
        orbPolicy: OrbPolicy = .default
    ) -> CrossAspectGrid {
        AspectEngine.crossGrid(
            natal: natalStates, transit: transitStates,
            aspectKinds: aspectKinds, orbPolicy: orbPolicy
        ).grid
    }

    /// One-step natal aspect table: motion-rich states + grid + optional zodiac ascendant.
    public static func natalAspects(
        for moment: CivilMoment,
        coordinate: GeoCoordinate? = nil,
        bodies: Set<CelestialBody> = [],
        includeAscendant: Bool = false,
        aspectKinds: Set<AspectKind> = AspectKind.ptolemaic,
        orbPolicy: OrbPolicy = .default
    ) throws(AstrologyError) -> NatalAspects {
        var asc: AscendantResult?
        if includeAscendant {
            guard let coordinate else { throw .missingCoordinateForAscendant }
            asc = try ascendant(for: moment, coordinate: coordinate)
        }
        let states = AstroCalculator.states(of: bodies, at: moment)
        let grid = AspectEngine.buildGrid(
            among: states, aspectKinds: aspectKinds, orbPolicy: orbPolicy
        ).grid
        return NatalAspects(states: states, grid: grid, ascendant: asc)
    }
}
