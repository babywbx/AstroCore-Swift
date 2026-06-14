import AstroCore
import Foundation

// Computes the four chart angles (ASC, MC, DSC, IC) and Vertex.
//
// ASC and MC come from core Axis; this engine adds Vertex and
// packages them into an `Angles` struct.
//
// MC (Medium Coeli): intersection of the upper meridian with the ecliptic.
//   λ_MC = atan2(sin(ARMC), cos(ARMC) × cos(ε))
//
// Vertex: western intersection of the prime vertical with the ecliptic.
//   Computed as an ASC-style formula using colatitude and RAMC + 180°.
enum AnglesEngine {
    /// Compute all angles for a moment and coordinate.
    /// - Throws: `AstrologyError.core(.extremeLatitude)` when the ASC is undefined.
    static func compute(
        for moment: CivilMoment,
        coordinate: GeoCoordinate
    ) throws(AstrologyError) -> Angles {
        let lastDeg = moment.localApparentSiderealTime(longitude: coordinate.longitude)
        let trueObl = moment.trueObliquity

        let asc: Double
        do {
            asc = try AstroCalculator.ascendantLongitude(for: moment, coordinate: coordinate)
        } catch {
            throw AstrologyError.core(error)
        }
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
        Axis.midheavenLongitude(
            lastDegrees: lastDegrees,
            trueObliquityDegrees: trueObliquityDegrees
        )
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

        let zenith = EquatorialVector(
            rightAscension: lastDegrees,
            declination: latitudeDegrees
        )
        let westHorizon = EquatorialVector.horizonPoint(
            azimuth: 270.0,
            lastDegrees: lastDegrees,
            latitudeDegrees: latitudeDegrees
        )
        let planeNormal = zenith.cross(westHorizon)
        let candidate = planeNormal.eclipticIntersectionLongitude(
            obliquityDegrees: trueObliquityDegrees
        )

        if latitudeDegrees >= 0 {
            return candidate
        }
        return AngleMath.normalized(degrees: candidate + 180.0)
    }
}
