import Foundation

// Heliocentric → geocentric conversion for planets with light-time correction
enum PlanetaryPosition {
    /// Compute geocentric ecliptic position of a planet.
    /// tau: Julian millennia from J2000.0 in TT
    static func compute(_ body: CelestialBody, tau: Double) -> CelestialPosition {
        let earth = VSOP87D.earthPosition(tau: tau)

        // Iterate light-time correction (2 iterations sufficient)
        var planetTau = tau
        var planet = VSOP87D.planetPosition(body, tau: planetTau)

        for _ in 0..<2 {
            let earthRect = rectangular(from: earth)
            let planetRect = rectangular(from: planet)
            let dx = planetRect.x - earthRect.x
            let dy = planetRect.y - earthRect.y
            let dz = planetRect.z - earthRect.z
            let distance = Foundation.sqrt(dx * dx + dy * dy + dz * dz)
            // Light-time in Julian millennia: 0.0057755183 days/AU → millennia
            let lightTimeMill = 0.0057755183 * distance / 365250.0
            planetTau = tau - lightTimeMill
            planet = VSOP87D.planetPosition(body, tau: planetTau)
        }

        // Final rectangular conversion
        let earthRect = rectangular(from: earth)
        let planetRect = rectangular(from: planet)

        let dx = planetRect.x - earthRect.x
        let dy = planetRect.y - earthRect.y
        let dz = planetRect.z - earthRect.z

        // Convert to geocentric ecliptic spherical
        let lonRad = Foundation.atan2(dy, dx)
        let dist = Foundation.sqrt(dx * dx + dy * dy + dz * dz)
        let latRad = Foundation.asin(dz / dist)

        let lonDeg = AngleMath.normalized(degrees: AngleMath.toDegrees(lonRad))
        let latDeg = AngleMath.toDegrees(latRad)

        let sign = ZodiacMapper.sign(forLongitude: lonDeg)
        let degInSign = ZodiacMapper.degreeInSign(longitude: lonDeg)
        let boundary = ZodiacMapper.isBoundaryCase(longitude: lonDeg)

        return CelestialPosition(
            body: body,
            longitude: lonDeg,
            latitude: latDeg,
            sign: sign,
            degreeInSign: degInSign,
            isBoundaryCase: boundary
        )
    }

    private static func rectangular(
        from position: VSOP87D.SphericalPosition
    ) -> (x: Double, y: Double, z: Double) {
        let cosLat = Foundation.cos(position.latitude)
        return (
            x: position.radius * cosLat * Foundation.cos(position.longitude),
            y: position.radius * cosLat * Foundation.sin(position.longitude),
            z: position.radius * Foundation.sin(position.latitude)
        )
    }
}
