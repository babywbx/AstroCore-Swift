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
        var best: Aspect?
        for kind in AspectKind.allCases where aspectKinds.contains(kind) {
            let deviation = AstroCalculator.aspectSeparation(
                longitudeA: first.longitude,
                longitudeB: second.longitude,
                aspectAngleDegrees: kind.angleDegrees
            )
            let allowed = orbPolicy.allowedOrb(for: kind, bodyA: first.body, bodyB: second.body)
            guard abs(deviation) <= allowed else { continue }
            if let best, abs(best.deviation) <= abs(deviation) { continue }
            let closingRate = AstroCalculator.aspectClosingRate(
                speedA: first.speed,
                speedB: second.speed,
                longitudeA: first.longitude,
                longitudeB: second.longitude,
                aspectAngleDegrees: kind.angleDegrees
            )
            best = Aspect(
                bodyA: first.body,
                bodyB: second.body,
                kind: kind,
                deviation: deviation,
                allowedOrb: allowed,
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
}
