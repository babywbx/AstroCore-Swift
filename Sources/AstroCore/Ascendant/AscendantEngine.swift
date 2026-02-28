import Foundation

// Ascendant (Rising Sign) calculation engine
// λ_ASC = atan2( −cos(LAST), sin(ε)×tan(φ) + cos(ε)×sin(LAST) )
enum AscendantEngine {
    /// Compute the ascendant for a given moment and geographic coordinate.
    static func compute(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) throws(AstroError) -> AscendantResult {
        try coordinate.validateForAscendant()

        let jdUT = try JulianDay.julianDay(for: moment)
        let dt = DeltaT.deltaT(decimalYear: moment.decimalYear)
        let tTT = JulianDay.julianCenturiesTT(jdUT: jdUT, deltaT: dt)

        // Nutation and obliquity
        let nut = Nutation.compute(julianCenturiesTT: tTT)
        let meanObl = Obliquity.meanObliquity(julianCenturiesTT: tTT)
        let trueObl = meanObl + nut.obliquity / 3600.0

        // Local Apparent Sidereal Time
        let lastDeg = SiderealTime.last(
            jdUT: jdUT, longitude: coordinate.longitude,
            nutationLongitude: nut.longitude, trueObliquity: trueObl
        )

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

        let y = -Foundation.cos(lastRad)
        let x = Foundation.sin(oblRad) * Foundation.tan(latRad)
            + Foundation.cos(oblRad) * Foundation.sin(lastRad)

        let ascRad = Foundation.atan2(y, x)
        // Add 180° to select the eastern (ascending) intersection
        return AngleMath.normalized(degrees: AngleMath.toDegrees(ascRad) + 180.0)
    }
}
