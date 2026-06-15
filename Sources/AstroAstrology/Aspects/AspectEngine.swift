import AstroCore

/// Internal aspect resolution shared by single-pair and matrix entry points.
enum AspectEngine {
    /// |deviation| within this threshold marks the aspect as partile (exact).
    static let partileOrbDegrees = 1.0

    /// Stable CaseIterable position per body, for O(1) canonical ordering.
    static let bodyOrder: [CelestialBody: Int] = Dictionary(
        uniqueKeysWithValues: CelestialBody.allCases.enumerated().map { ($1, $0) }
    )

    /// Resolve the tightest matching aspect (if any) between two motion-rich states.
    static func resolve(
        _ stateA: CelestialState,
        _ stateB: CelestialState,
        aspectKinds: Set<AspectKind>,
        orbPolicy: OrbPolicy
    ) -> Aspect? {
        guard stateA.body != stateB.body else { return nil }
        let (first, second) = canonicalOrder(stateA, stateB)
        return resolveOrdered(
            bodyA: first.body, longitudeA: first.longitude, speedA: first.speed,
            bodyB: second.body, longitudeB: second.longitude, speedB: second.speed,
            aspectKinds: aspectKinds, orbPolicy: orbPolicy
        )
    }

    /// Core resolution for a pair already in canonical (bodyA-before-bodyB) order.
    static func resolveOrdered(
        bodyA: CelestialBody, longitudeA: Double, speedA: Double,
        bodyB: CelestialBody, longitudeB: Double, speedB: Double,
        aspectKinds: Set<AspectKind>, orbPolicy: OrbPolicy
    ) -> Aspect? {
        var best: Aspect?
        for kind in AspectKind.allCases where aspectKinds.contains(kind) {
            let deviation = AstroCalculator.aspectSeparation(
                longitudeA: longitudeA, longitudeB: longitudeB, aspectAngleDegrees: kind.angleDegrees
            )
            let allowed = orbPolicy.allowedOrb(for: kind, bodyA: bodyA, bodyB: bodyB)
            guard abs(deviation) <= allowed else { continue }
            if let best, abs(best.deviation) <= abs(deviation) { continue }
            let closingRate = AstroCalculator.aspectClosingRate(
                speedA: speedA, speedB: speedB,
                longitudeA: longitudeA, longitudeB: longitudeB, aspectAngleDegrees: kind.angleDegrees
            )
            best = Aspect(
                bodyA: bodyA, bodyB: bodyB, kind: kind,
                deviation: deviation, allowedOrb: allowed,
                isApplying: closingRate > 0,
                isExact: abs(deviation) <= partileOrbDegrees
            )
        }
        return best
    }

    static func canonicalOrder(
        _ a: CelestialState,
        _ b: CelestialState
    ) -> (CelestialState, CelestialState) {
        (bodyOrder[a.body] ?? 0) <= (bodyOrder[b.body] ?? 0) ? (a, b) : (b, a)
    }

    /// Build the upper-triangular grid; returns it plus the number of pairs compared.
    static func buildGrid(
        among states: [CelestialBody: CelestialState],
        aspectKinds: Set<AspectKind>,
        orbPolicy: OrbPolicy
    ) -> (grid: AspectGrid, comparisons: Int) {
        let entries = states.sorted { (bodyOrder[$0.key] ?? 0) < (bodyOrder[$1.key] ?? 0) }
        let bodies = entries.map(\.key)
        let longitudes = entries.map(\.value.longitude)
        let speeds = entries.map(\.value.speed)
        let n = bodies.count

        var matched: [Aspect] = []
        matched.reserveCapacity(n * (n - 1) / 2)
        var comparisons = 0
        for i in 0..<n {
            for j in (i + 1)..<n {
                comparisons += 1
                if let aspect = resolveOrdered(
                    bodyA: bodies[i], longitudeA: longitudes[i], speedA: speeds[i],
                    bodyB: bodies[j], longitudeB: longitudes[j], speedB: speeds[j],
                    aspectKinds: aspectKinds, orbPolicy: orbPolicy
                ) {
                    matched.append(aspect)
                }
            }
        }
        return (AspectGrid(bodies: bodies, aspects: matched), comparisons)
    }

    /// Matrix from a moment via a (test-injectable) states provider; states is resolved exactly once.
    static func gridAspects(
        for moment: CivilMoment,
        bodies: Set<CelestialBody>,
        aspectKinds: Set<AspectKind>,
        orbPolicy: OrbPolicy,
        statesProvider: (Set<CelestialBody>, CivilMoment) -> [CelestialBody: CelestialState]
    ) -> (grid: AspectGrid, comparisons: Int) {
        let states = statesProvider(bodies, moment)
        return buildGrid(among: states, aspectKinds: aspectKinds, orbPolicy: orbPolicy)
    }
}
