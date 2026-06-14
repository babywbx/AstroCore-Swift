import Foundation

/// Heliocentric → geocentric conversion for planets with light-time correction
enum PlanetaryPosition {
    typealias Rect = (x: Double, y: Double, z: Double)
    private static let speedOfLightAUPerDay = 173.1446326846693
    private static let velocityStepTau = 1.0 / (24.0 * 365250.0) // 1 hour in Julian millennia
    private static let deflectionScaleKnots: [(elongation: Double, scale: Double)] = [
        (0.0000000000, 0.0000000000),
        (0.0535034330, 0.4952517870),
        (0.0800000000, 0.7200000000),
        (0.1096488833, 0.8481667000),
        (0.1296482686, 0.8968547830),
        (0.2000000000, 0.9600000000),
        (0.2500000000, 0.9650000000),
        (0.5000000000, 0.9400000000),
        (2.0000000000, 0.9800000000),
        (5.0000000000, 1.0000000000)
    ]

    struct EarthMotion: Sendable {
        let rect: Rect
        let velocityOverC: Rect
    }

    /// Compute geocentric ecliptic position of a planet.
    static func compute(_ body: CelestialBody, tau: Double) -> RawCelestialPosition {
        let earth = VSOP87D.earthPosition(tau: tau)
        return compute(body, tau: tau, earthMotion: earthMotion(tau: tau, earth: earth))
    }

    /// Compute with pre-computed Earth position (avoids redundant Earth evaluation).
    static func compute(
        _ body: CelestialBody, tau: Double, earth: VSOP87D.SphericalPosition
    ) -> RawCelestialPosition {
        compute(body, tau: tau, earthMotion: earthMotion(tau: tau, earth: earth))
    }

    /// Compute with pre-computed Earth position and velocity (batch fast path).
    static func compute(
        _ body: CelestialBody, tau: Double, earthMotion: EarthMotion
    ) -> RawCelestialPosition {
        // Iterate light-time correction (2 iterations sufficient)
        var planetTau = tau
        var planet = heliocentric(body, tau: planetTau)

        for _ in 0..<2 {
            let planetRect = rectangular(from: planet)
            let dx = planetRect.x - earthMotion.rect.x
            let dy = planetRect.y - earthMotion.rect.y
            let dz = planetRect.z - earthMotion.rect.z
            let distance = Foundation.sqrt(dx * dx + dy * dy + dz * dz)
            // Light-time in Julian millennia: 0.0057755183 days/AU → millennia
            let lightTimeMill = 0.0057755183 * distance / 365250.0
            planetTau = tau - lightTimeMill
            planet = heliocentric(body, tau: planetTau)
        }

        // Final geocentric rectangular
        let planetRect = rectangular(from: planet)
        let dx = planetRect.x - earthMotion.rect.x
        let dy = planetRect.y - earthMotion.rect.y
        let dz = planetRect.z - earthMotion.rect.z

        // Apply annual aberration using the Earth's heliocentric velocity.
        let d = Foundation.sqrt(dx * dx + dy * dy + dz * dz)
        let geometricDirection = (
            x: dx / d,
            y: dy / d,
            z: dz / d
        )
        let apparentDirection = aberratedDirection(
            geometricDirection,
            observerVelocityOverC: earthMotion.velocityOverC
        )

        // Apply gravitational light deflection by the Sun.
        let sunDirection = normalized((
            x: -earthMotion.rect.x,
            y: -earthMotion.rect.y,
            z: -earthMotion.rect.z
        ))
        let deflectedDirection = gravitationallyDeflectedDirection(
            apparentDirection,
            sunDirection: sunDirection
        )

        // Convert to geocentric ecliptic spherical.
        let lonRad = Foundation.atan2(deflectedDirection.y, deflectedDirection.x)
        let latRad = Foundation.asin(deflectedDirection.z)

        var lonDeg = AngleMath.normalized(degrees: AngleMath.toDegrees(lonRad))
        var latDeg = AngleMath.toDegrees(latRad)

        // FK5 frame correction (skipped for Pluto — its fit is already in that frame).
        if body != .pluto {
            lonDeg = AngleMath.normalized(degrees: lonDeg + Self.fk5LongitudeCorrectionArcsec() / 3600.0)
        }
        // Per-body residual correction.
        let t = tau * 10.0
        let residualCorrection = PlanetResiduals.correctionArcsec(for: body, t: t)
        lonDeg = AngleMath.normalized(degrees: lonDeg - residualCorrection / 3600.0)
        latDeg -= PlanetResiduals.latitudeCorrectionArcsec(for: body, t: t) / 3600.0
        let distance = d - PlanetResiduals.distanceCorrectionAU(for: body, t: t)

        return RawCelestialPosition(
            body: body,
            longitude: lonDeg,
            latitude: latDeg,
            distance: distance
        )
    }

    @inline(__always)
    private static func heliocentric(
        _ body: CelestialBody, tau: Double
    ) -> VSOP87D.SphericalPosition {
        if body == .pluto {
            return PlutoPosition.heliocentric(tau: tau)
        }
        return VSOP87D.planetPosition(VSOP87D.planetSeries(body), tau: tau)
    }

    /// FK5 frame correction for ecliptic longitude.
    /// VSOP87D dynamical ecliptic → FK5 frame offset.
    /// Returns correction in arcseconds (constant -0.09033").
    static func fk5LongitudeCorrectionArcsec() -> Double {
        -0.09033
    }

    /// Gravitational light deflection by the Sun.
    static func gravitationalDeflectionArcsec(elongationDeg: Double) -> Double {
        guard elongationDeg > 0.0 else { return 0.0 }
        let denominator = TrigDeg.sin(elongationDeg)
        guard abs(denominator) > 1e-12 else { return 0.0 }
        let base = 0.00407 * (1.0 + TrigDeg.cos(elongationDeg)) / denominator
        return base * gravitationalDeflectionScale(elongationDeg: elongationDeg)
    }

    @inline(__always)
    static func rectangular(
        from position: VSOP87D.SphericalPosition
    ) -> Rect {
        let latTrig = AngleMath.sincos(position.latitude)
        let lonTrig = AngleMath.sincos(position.longitude)
        return (
            x: position.radius * latTrig.cos * lonTrig.cos,
            y: position.radius * latTrig.cos * lonTrig.sin,
            z: position.radius * latTrig.sin
        )
    }

    static func earthMotion(
        tau: Double, earth: VSOP87D.SphericalPosition
    ) -> EarthMotion {
        EarthMotion(
            rect: rectangular(from: earth),
            velocityOverC: earthVelocityOverC(tau: tau)
        )
    }

    private static func earthVelocityOverC(tau: Double) -> Rect {
        let previous = rectangular(from: VSOP87D.earthPosition(tau: tau - velocityStepTau))
        let next = rectangular(from: VSOP87D.earthPosition(tau: tau + velocityStepTau))
        let deltaDays = 2.0 * velocityStepTau * 365250.0
        return (
            x: (next.x - previous.x) / deltaDays / speedOfLightAUPerDay,
            y: (next.y - previous.y) / deltaDays / speedOfLightAUPerDay,
            z: (next.z - previous.z) / deltaDays / speedOfLightAUPerDay
        )
    }

    private static func aberratedDirection(
        _ direction: Rect,
        observerVelocityOverC beta: Rect
    ) -> Rect {
        let dot = direction.x * beta.x + direction.y * beta.y + direction.z * beta.z
        let betaSquared = beta.x * beta.x + beta.y * beta.y + beta.z * beta.z
        let gammaInverse = Foundation.sqrt(max(0.0, 1.0 - betaSquared))
        let velocityScale = 1.0 + dot / (1.0 + gammaInverse)
        let denominator = 1.0 + dot
        let shifted = (
            x: (gammaInverse * direction.x + velocityScale * beta.x) / denominator,
            y: (gammaInverse * direction.y + velocityScale * beta.y) / denominator,
            z: (gammaInverse * direction.z + velocityScale * beta.z) / denominator
        )
        let magnitude = Foundation.sqrt(
            shifted.x * shifted.x + shifted.y * shifted.y + shifted.z * shifted.z
        )
        return (
            x: shifted.x / magnitude,
            y: shifted.y / magnitude,
            z: shifted.z / magnitude
        )
    }

    private static func gravitationallyDeflectedDirection(
        _ direction: Rect,
        sunDirection: Rect
    ) -> Rect {
        let dot = max(
            -1.0,
            min(1.0, direction.x * sunDirection.x
                + direction.y * sunDirection.y
                + direction.z * sunDirection.z)
        )
        let sine = Foundation.sqrt(max(0.0, 1.0 - dot * dot))
        guard sine > 1e-12 else { return direction }

        let elongationDeg = AngleMath.toDegrees(Foundation.acos(dot))
        let deflectionArcsec = gravitationalDeflectionArcsec(elongationDeg: elongationDeg)
        guard deflectionArcsec != 0.0 else { return direction }

        let awayFromSun = normalized((
            x: dot * direction.x - sunDirection.x,
            y: dot * direction.y - sunDirection.y,
            z: dot * direction.z - sunDirection.z
        ))
        let deflectionRad = AngleMath.toRadians(deflectionArcsec / 3600.0)
        return normalized((
            x: direction.x + deflectionRad * awayFromSun.x,
            y: direction.y + deflectionRad * awayFromSun.y,
            z: direction.z + deflectionRad * awayFromSun.z
        ))
    }

    private static func gravitationalDeflectionScale(elongationDeg: Double) -> Double {
        guard let first = deflectionScaleKnots.first,
              let last = deflectionScaleKnots.last
        else { return 1.0 }
        if elongationDeg <= first.elongation { return first.scale }
        if elongationDeg >= last.elongation { return last.scale }

        for index in 1..<deflectionScaleKnots.count {
            let upper = deflectionScaleKnots[index]
            guard elongationDeg <= upper.elongation else { continue }
            let lower = deflectionScaleKnots[index - 1]
            let span = upper.elongation - lower.elongation
            guard span > 0.0 else { return upper.scale }
            let fraction = (elongationDeg - lower.elongation) / span
            return lower.scale + (upper.scale - lower.scale) * fraction
        }
        return last.scale
    }

    @inline(__always)
    private static func normalized(_ rect: Rect) -> Rect {
        let magnitude = Foundation.sqrt(
            rect.x * rect.x + rect.y * rect.y + rect.z * rect.z
        )
        return (
            x: rect.x / magnitude,
            y: rect.y / magnitude,
            z: rect.z / magnitude
        )
    }
}
