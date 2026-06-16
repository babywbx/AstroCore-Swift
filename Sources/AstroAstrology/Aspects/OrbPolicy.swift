import AstroCore

public struct OrbPolicy: Sendable, Hashable, Codable {
    /// Per-aspect allowed orb used when no body weighting applies.
    public let baseOrbs: [AspectKind: Double]
    /// Per-body max orb weight; empty means use baseOrbs directly.
    public let bodyOrbModifiers: [CelestialBody: Double]
    /// Optional orb weight for chart angles (parallel to bodyOrbModifiers); nil = no angle widening.
    public let angleOrbModifier: Double?

    public init(
        baseOrbs: [AspectKind: Double],
        bodyOrbModifiers: [CelestialBody: Double] = [:],
        angleOrbModifier: Double? = nil
    ) {
        self.baseOrbs = baseOrbs
        self.bodyOrbModifiers = bodyOrbModifiers
        self.angleOrbModifier = angleOrbModifier
    }

    /// Fixed per-aspect orbs from AspectKind.defaultOrbDegrees, no body weighting.
    public static let `default` = OrbPolicy(
        baseOrbs: Dictionary(
            uniqueKeysWithValues: AspectKind.allCases.map { ($0, $0.defaultOrbDegrees) }
        )
    )

    /// Luminary-widened major aspects; minor aspects keep narrow fixed orbs.
    public static let luminariesWeighted = OrbPolicy(
        baseOrbs: OrbPolicy.default.baseOrbs,
        bodyOrbModifiers: [
            .sun: 10.0, .moon: 10.0,
            .mercury: 7.0, .venus: 7.0, .mars: 7.0,
            .jupiter: 6.0, .saturn: 6.0,
            .uranus: 5.0, .neptune: 5.0, .pluto: 5.0,
            .meanNode: 3.0, .trueNode: 3.0,
            .lilith: 2.0, .trueLilith: 2.0
        ]
    )

    /// Max allowed orb for this (kind, A, B) triple (the spoken "orb").
    public func allowedOrb(
        for kind: AspectKind,
        bodyA: CelestialBody,
        bodyB: CelestialBody
    ) -> Double {
        let base = baseOrbs[kind] ?? kind.defaultOrbDegrees
        guard !bodyOrbModifiers.isEmpty, kind.isMajor else { return base }
        let modifierA = bodyOrbModifiers[bodyA]
        let modifierB = bodyOrbModifiers[bodyB]
        guard modifierA != nil || modifierB != nil else { return base }
        return max(modifierA ?? base, modifierB ?? base) * kind.majorOrbScale
    }

    /// Max allowed orb for a (kind, participant, participant) triple. Body-body delegates to the
    /// body rule; angle endpoints weight by `angleOrbModifier`.
    public func allowedOrb(
        for kind: AspectKind,
        participantA: AspectParticipant,
        participantB: AspectParticipant
    ) -> Double {
        if case .body(let a) = participantA, case .body(let b) = participantB {
            return allowedOrb(for: kind, bodyA: a, bodyB: b)
        }
        let base = baseOrbs[kind] ?? kind.defaultOrbDegrees
        let usesWeighting = !bodyOrbModifiers.isEmpty || angleOrbModifier != nil
        guard usesWeighting, kind.isMajor else { return base }
        let modifierA = modifier(for: participantA)
        let modifierB = modifier(for: participantB)
        guard modifierA != nil || modifierB != nil else { return base }
        return max(modifierA ?? base, modifierB ?? base) * kind.majorOrbScale
    }

    private func modifier(for participant: AspectParticipant) -> Double? {
        switch participant {
        case .body(let body): bodyOrbModifiers[body]
        case .angle: angleOrbModifier
        }
    }
}
