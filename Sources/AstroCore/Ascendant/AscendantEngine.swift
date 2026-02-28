import Foundation

// Ascendant (Rising Sign) calculation engine
// λ_ASC = atan2( −cos(LAST), sin(ε)×tan(φ) + cos(ε)×sin(LAST) )
enum AscendantEngine {
    /// Compute the ascendant for a given moment and geographic coordinate.
    static func compute(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) throws(AstroError) -> AscendantResult {
        try coordinate.validateForAscendant()

        let jdUT = moment.julianDayUT
        let trueObl = moment.trueObliquity

        // Local Apparent Sidereal Time
        let lastDeg = moment.localApparentSiderealTime(longitude: coordinate.longitude)

        // Ascendant longitude
        let ascLon = ascendantLongitude(
            lastDegrees: lastDeg,
            trueObliquityDegrees: trueObl,
            latitudeDegrees: coordinate.latitude
        )
        let zodiac = ZodiacMapper.details(forNormalizedLongitude: ascLon)

        return AscendantResult(
            eclipticLongitude: ascLon,
            sign: zodiac.sign,
            degreeInSign: zodiac.degreeInSign,
            localSiderealTimeDegrees: lastDeg,
            julianDayUT: jdUT,
            trueObliquity: trueObl,
            isBoundaryCase: zodiac.isBoundaryCase
        )
    }

    /// Core ascendant formula using atan2.
    /// Returns ecliptic longitude in [0, 360).
    static func ascendantLongitude(
        lastDegrees: Double,
        trueObliquityDegrees: Double,
        latitudeDegrees: Double
    ) -> Double {
        let lastRad = AngleMath.toRadians(lastDegrees)
        let oblRad = AngleMath.toRadians(trueObliquityDegrees)
        let latRad = AngleMath.toRadians(latitudeDegrees)
        let lastTrig = AngleMath.sincos(lastRad)
        let oblTrig = AngleMath.sincos(oblRad)

        let y = -lastTrig.cos
        let x = oblTrig.sin * Foundation.tan(latRad)
            + oblTrig.cos * lastTrig.sin

        let ascRad = Foundation.atan2(y, x)
        // Add 180° to select the eastern (ascending) intersection
        return AngleMath.normalized(degrees: AngleMath.toDegrees(ascRad) + 180.0)
    }
}
