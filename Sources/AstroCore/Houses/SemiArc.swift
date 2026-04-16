import Foundation

// Semi-diurnal / semi-nocturnal arc computations.
//
// For a point on the celestial sphere with declination δ observed from
// geographic latitude φ, the hour angle H at which the point crosses the
// horizon satisfies:
//   cos(H) = −tan(φ) × tan(δ)
// H is the semi-diurnal arc (time above the horizon from rise to upper
// transit, in degrees). The semi-nocturnal arc is 180° − H.
//
// When |tan(φ) × tan(δ)| > 1 the point is circumpolar (never rises or never
// sets). Callers must check `isCircumpolar` before using the result.
enum SemiArc {
    struct Result: Sendable, Hashable {
        /// Declination of the point, in degrees.
        let declinationDegrees: Double
        /// Right ascension of the point, in degrees [0, 360).
        let rightAscensionDegrees: Double
        /// Semi-diurnal arc in degrees, nil if the point is circumpolar.
        let semiDiurnalArc: Double?
        /// True if |tan(φ) × tan(δ)| > 1 (never rises or never sets).
        let isCircumpolar: Bool
    }

    /// Convert an ecliptic longitude (with β = 0) to (α, δ) on the equator and
    /// compute the semi-diurnal arc at the given latitude.
    static func compute(
        eclipticLongitude lonDeg: Double,
        obliquity oblDeg: Double,
        latitude latDeg: Double
    ) -> Result {
        let lonTrig = AngleMath.sincos(AngleMath.toRadians(lonDeg))
        let oblTrig = AngleMath.sincos(AngleMath.toRadians(oblDeg))

        // Equatorial coordinates from ecliptic (β = 0):
        // α = atan2(sin(λ)×cos(ε), cos(λ))
        // δ = arcsin(sin(λ)×sin(ε))
        let alphaRad = Foundation.atan2(lonTrig.sin * oblTrig.cos, lonTrig.cos)
        let deltaRad = Foundation.asin(lonTrig.sin * oblTrig.sin)
        let alphaDeg = AngleMath.normalized(degrees: AngleMath.toDegrees(alphaRad))
        let deltaDeg = AngleMath.toDegrees(deltaRad)

        let latRad = AngleMath.toRadians(latDeg)
        let product = Foundation.tan(latRad) * Foundation.tan(deltaRad)

        if abs(product) > 1.0 {
            return Result(
                declinationDegrees: deltaDeg,
                rightAscensionDegrees: alphaDeg,
                semiDiurnalArc: nil,
                isCircumpolar: true
            )
        }

        let hRad = Foundation.acos(-product)
        return Result(
            declinationDegrees: deltaDeg,
            rightAscensionDegrees: alphaDeg,
            semiDiurnalArc: AngleMath.toDegrees(hRad),
            isCircumpolar: false
        )
    }
}
