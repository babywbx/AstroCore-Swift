import Foundation

// Heliocentric → geocentric conversion for planets with light-time correction
enum PlanetaryPosition {
    typealias Rect = (x: Double, y: Double, z: Double)
    private static let speedOfLightAUPerDay = 173.1446326846693
    private static let velocityStepTau = 1.0 / (24.0 * 365250.0) // 1 hour in Julian millennia

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
        let series = VSOP87D.planetSeries(body)

        // Iterate light-time correction (2 iterations sufficient)
        var planetTau = tau
        var planet = VSOP87D.planetPosition(series, tau: planetTau)

        for _ in 0..<2 {
            let planetRect = rectangular(from: planet)
            let dx = planetRect.x - earthMotion.rect.x
            let dy = planetRect.y - earthMotion.rect.y
            let dz = planetRect.z - earthMotion.rect.z
            let distance = Foundation.sqrt(dx * dx + dy * dy + dz * dz)
            // Light-time in Julian millennia: 0.0057755183 days/AU → millennia
            let lightTimeMill = 0.0057755183 * distance / 365250.0
            planetTau = tau - lightTimeMill
            planet = VSOP87D.planetPosition(series, tau: planetTau)
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

        // Convert to geocentric ecliptic spherical.
        let lonRad = Foundation.atan2(apparentDirection.y, apparentDirection.x)
        let latRad = Foundation.asin(apparentDirection.z)

        let lonDeg = AngleMath.normalized(degrees: AngleMath.toDegrees(lonRad))
        let latDeg = AngleMath.toDegrees(latRad)

        return RawCelestialPosition(
            body: body,
            longitude: lonDeg,
            latitude: latDeg
        )
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
}
