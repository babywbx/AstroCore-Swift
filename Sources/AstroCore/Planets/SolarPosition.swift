import Foundation

// Solar position from Earth's VSOP87D
// λ_Sun = L_Earth + 180°, β_Sun = −B_Earth
// Plus FK5 correction and aberration
enum SolarPosition {
    /// Compute geocentric ecliptic position of the Sun.
    static func compute(tau: Double, t: Double) -> CelestialPosition {
        compute(tau: tau, t: t, earth: VSOP87D.earthPosition(tau: tau))
    }

    /// Compute with pre-computed Earth position (avoids redundant Earth evaluation).
    static func compute(
        tau: Double, t: Double, earth: VSOP87D.SphericalPosition
    ) -> CelestialPosition {

        // Geocentric longitude = Earth's helio longitude + 180°
        var sunLon = earth.longitude + .pi
        let sunLat = -earth.latitude

        // FK5 correction (Meeus p.166)
        let lp = AngleMath.toDegrees(sunLon) - 1.397 * t - 0.00031 * t * t
        let fk5Lon = -0.09033 / 3600.0 // degrees
        let fk5Lat = (0.03916 * (TrigDeg.cos(lp) - TrigDeg.sin(lp))) / 3600.0
        sunLon += AngleMath.toRadians(fk5Lon)
        let corrLat = sunLat + AngleMath.toRadians(fk5Lat)

        // Aberration: −20.4898″ / R (Meeus Eq. 25.10)
        let aberration = -20.4898 / 3600.0 / earth.radius
        sunLon += AngleMath.toRadians(aberration)

        // Convert to degrees and normalize
        let lonDeg = AngleMath.normalized(degrees: AngleMath.toDegrees(sunLon))
        let latDeg = AngleMath.toDegrees(corrLat)
        let zodiac = ZodiacMapper.details(forNormalizedLongitude: lonDeg)

        return CelestialPosition(
            body: .sun,
            longitude: lonDeg,
            latitude: latDeg,
            sign: zodiac.sign,
            degreeInSign: zodiac.degreeInSign,
            isBoundaryCase: zodiac.isBoundaryCase
        )
    }
}
