import Foundation

// Sidereal Time — Meeus Ch.12
enum SiderealTime {
    /// Greenwich Mean Sidereal Time in degrees.
    /// Input: JD in UT.
    static func gmst(jdUT: Double) -> Double {
        let t = JulianDay.julianCenturiesUT(jd: jdUT)
        // Meeus Eq. 12.4
        let theta = 280.46061837
            + 360.98564736629 * (jdUT - JulianDay.j2000)
            + 0.000387933 * t * t
            - t * t * t / 38710000.0
        return AngleMath.normalized(degrees: theta)
    }

    /// Greenwich Apparent Sidereal Time in degrees.
    /// Requires nutation in longitude (Δψ) in arcseconds
    /// and true obliquity (ε) in degrees.
    static func gast(
        jdUT: Double, nutationLongitude: Double, trueObliquity: Double
    ) -> Double {
        let gmstDeg = gmst(jdUT: jdUT)
        // Equation of the equinoxes: Δψ × cos(ε)
        // nutationLongitude is in arcseconds, convert to degrees
        let eqEq = (nutationLongitude / 3600.0) * TrigDeg.cos(trueObliquity)
        return AngleMath.normalized(degrees: gmstDeg + eqEq)
    }

    /// Local Apparent Sidereal Time in degrees.
    /// longitude: east positive, in degrees.
    static func last(
        jdUT: Double, longitude: Double,
        nutationLongitude: Double, trueObliquity: Double
    ) -> Double {
        let gastDeg = gast(
            jdUT: jdUT,
            nutationLongitude: nutationLongitude,
            trueObliquity: trueObliquity
        )
        return AngleMath.normalized(degrees: gastDeg + longitude)
    }
}
