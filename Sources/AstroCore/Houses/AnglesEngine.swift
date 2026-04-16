import Foundation

// Computes the four chart angles (ASC, MC, DSC, IC) and Vertex.
//
// ASC is computed by AscendantEngine; this engine adds MC and Vertex and
// packages them into an `Angles` struct.
//
// MC (Medium Coeli): intersection of the upper meridian with the ecliptic.
//   λ_MC = atan2(sin(ARMC), cos(ARMC) × cos(ε))
//
// Vertex: western intersection of the prime vertical with the ecliptic.
//   Computed as an ASC-style formula using colatitude and RAMC + 180°.
enum AnglesEngine {
    /// Compute all angles for a moment and coordinate.
    /// - Throws: `AstroError.extremeLatitude` when the ASC is undefined.
    static func compute(
        for moment: CivilMoment,
        coordinate: GeoCoordinate
    ) throws(AstroError) -> Angles {
        try coordinate.validateForAscendant()

        let lastDeg = moment.localApparentSiderealTime(longitude: coordinate.longitude)
        let trueObl = moment.trueObliquity

        let asc = AscendantEngine.ascendantLongitude(
            lastDegrees: lastDeg,
            trueObliquityDegrees: trueObl,
            latitudeDegrees: coordinate.latitude
        )
        let mc = midheavenLongitude(
            lastDegrees: lastDeg,
            trueObliquityDegrees: trueObl
        )
        let vtx = vertexLongitude(
            lastDegrees: lastDeg,
            trueObliquityDegrees: trueObl,
            latitudeDegrees: coordinate.latitude
        )

        return Angles(ascendant: asc, midheaven: mc, vertex: vtx)
    }

    /// Core MC formula: λ_MC = atan2(sin(ARMC), cos(ARMC) × cos(ε)).
    /// ARMC is LAST expressed in degrees.
    static func midheavenLongitude(
        lastDegrees: Double,
        trueObliquityDegrees: Double
    ) -> Double {
        let lastTrig = AngleMath.sincos(AngleMath.toRadians(lastDegrees))
        let oblCos = Foundation.cos(AngleMath.toRadians(trueObliquityDegrees))
        let mcRad = Foundation.atan2(lastTrig.sin, lastTrig.cos * oblCos)
        return AngleMath.normalized(degrees: AngleMath.toDegrees(mcRad))
    }

    /// Vertex longitude using the colatitude / RAMC+180° ASC-equivalent formula.
    ///
    /// Degenerate near the equator (|φ| < 0.1°); returns nil there.
    static func vertexLongitude(
        lastDegrees: Double,
        trueObliquityDegrees: Double,
        latitudeDegrees: Double
    ) -> Double? {
        let absLat = abs(latitudeDegrees)
        guard absLat >= 0.1 else { return nil }

        // Vertex = ASC formula at colatitude (90° − |φ|) and LAST + 180°.
        // Sign conventions follow Swiss Ephemeris: for the southern hemisphere
        // the resulting longitude is shifted by 180° (the Vertex becomes the
        // Antivertex seen from the northern hemisphere's perspective).
        let colat = 90.0 - absLat
        let shiftedLast = AngleMath.normalized(degrees: lastDegrees + 180.0)

        let asc = AscendantEngine.ascendantLongitude(
            lastDegrees: shiftedLast,
            trueObliquityDegrees: trueObliquityDegrees,
            latitudeDegrees: colat
        )

        // Southern-hemisphere correction: flip by 180°.
        if latitudeDegrees < 0 {
            return AngleMath.normalized(degrees: asc + 180.0)
        }
        return asc
    }
}
