import AstroCore

extension AstrologyCalculator {
    /// Aspect patterns (stellium, grand trine, T-square, …) recognised on an existing grid.
    /// Pure combinatorial detection over the grid edges; no ephemeris.
    public static func patterns(in grid: AspectGrid) -> [AspectPattern] {
        AspectPatternDetector.patterns(in: grid)
    }

    /// Aspects among bodies + chart angles at a moment/coordinate. Angles are fixed (speed 0). When
    /// `angles` is empty the body-body result matches `aspects(for:bodies:)`; angle longitudes come
    /// from `AnglesEngine`, and an angle undefined at the location (e.g. Vertex near the equator) is
    /// silently dropped.
    public static func chartAspects(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        bodies: Set<CelestialBody>,
        angles: Set<ChartAngle> = [.ascendant, .midheaven],
        aspectKinds: Set<AspectKind> = AspectKind.ptolemaic,
        orbPolicy: OrbPolicy = .default
    ) throws(AstrologyError) -> ChartAspectGrid {
        let states = AstroCalculator.states(of: bodies, at: moment)
        var participants: [(participant: AspectParticipant, longitude: Double, speed: Double)] = []
        for body in bodies.sorted(by: { (AspectEngine.bodyOrder[$0] ?? 0) < (AspectEngine.bodyOrder[$1] ?? 0) }) {
            guard let state = states[body] else { continue }
            participants.append((.body(body), state.longitude, state.speed))
        }
        if !angles.isEmpty {
            let resolved = try AnglesEngine.compute(for: moment, coordinate: coordinate)
            for angle in angles.sorted(by: { $0.rawValue < $1.rawValue }) {
                if let longitude = angleLongitude(angle, in: resolved) {
                    participants.append((.angle(angle), longitude, 0.0))
                }
            }
        }

        var matched: [ChartAspect] = []
        for i in 0..<participants.count {
            for j in (i + 1)..<participants.count {
                if let aspect = AspectEngine.resolveChartAspect(
                    participantA: participants[i].participant,
                    longitudeA: participants[i].longitude, speedA: participants[i].speed,
                    participantB: participants[j].participant,
                    longitudeB: participants[j].longitude, speedB: participants[j].speed,
                    aspectKinds: aspectKinds, orbPolicy: orbPolicy
                ) {
                    matched.append(aspect)
                }
            }
        }
        return ChartAspectGrid(participants: participants.map(\.participant), aspects: matched)
    }

    private static func angleLongitude(_ angle: ChartAngle, in angles: Angles) -> Double? {
        switch angle {
        case .ascendant: angles.ascendant
        case .midheaven: angles.midheaven
        case .descendant: angles.descendant
        case .imumCoeli: angles.imumCoeli
        case .vertex: angles.vertex
        }
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
