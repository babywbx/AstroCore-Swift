import Foundation

// Heliocentric → geocentric conversion for planets with light-time correction
enum PlanetaryPosition {
    typealias Rect = (x: Double, y: Double, z: Double)

    /// Compute geocentric ecliptic position of a planet.
    static func compute(_ body: CelestialBody, tau: Double) -> CelestialPosition {
        compute(body, tau: tau, earth: VSOP87D.earthPosition(tau: tau))
    }

    /// Compute with pre-computed Earth position (avoids redundant Earth evaluation).
    static func compute(
        _ body: CelestialBody, tau: Double, earth: VSOP87D.SphericalPosition
    ) -> CelestialPosition {
        let earthRect = rectangular(from: earth)

        // Iterate light-time correction (2 iterations sufficient)
        var planetTau = tau
        var planet = VSOP87D.planetPosition(body, tau: planetTau)

        for _ in 0..<2 {
            let planetRect = rectangular(from: planet)
            let distance = dist(earthRect, planetRect)
            // Light-time in Julian millennia: 0.0057755183 days/AU → millennia
            let lightTimeMill = 0.0057755183 * distance / 365250.0
            planetTau = tau - lightTimeMill
            planet = VSOP87D.planetPosition(body, tau: planetTau)
        }

        // Final geocentric rectangular
        let planetRect = rectangular(from: planet)
        let dx = planetRect.x - earthRect.x
        let dy = planetRect.y - earthRect.y
        let dz = planetRect.z - earthRect.z

        // Convert to geocentric ecliptic spherical
        let lonRad = Foundation.atan2(dy, dx)
        let d = Foundation.sqrt(dx * dx + dy * dy + dz * dz)
        let latRad = Foundation.asin(dz / d)

        let lonDeg = AngleMath.normalized(degrees: AngleMath.toDegrees(lonRad))
        let latDeg = AngleMath.toDegrees(latRad)

        return CelestialPosition(
            body: body,
            longitude: lonDeg,
            latitude: latDeg,
            sign: ZodiacMapper.sign(forLongitude: lonDeg),
            degreeInSign: ZodiacMapper.degreeInSign(longitude: lonDeg),
            isBoundaryCase: ZodiacMapper.isBoundaryCase(longitude: lonDeg)
        )
    }

    private static func rectangular(
        from position: VSOP87D.SphericalPosition
    ) -> Rect {
        let cosLat = Foundation.cos(position.latitude)
        return (
            x: position.radius * cosLat * Foundation.cos(position.longitude),
            y: position.radius * cosLat * Foundation.sin(position.longitude),
            z: position.radius * Foundation.sin(position.latitude)
        )
    }

    private static func dist(_ a: Rect, _ b: Rect) -> Double {
        let dx = b.x - a.x, dy = b.y - a.y, dz = b.z - a.z
        return Foundation.sqrt(dx * dx + dy * dy + dz * dz)
    }
}
