import Foundation

// Single public entry point for all astronomical calculations
public enum AstroCalculator {
    // --- Low-level (stable API) ---
    public static func julianDayUT(for moment: CivilMoment) throws -> Double {
        try JulianDay.julianDay(for: moment)
    }

    /// Returns Local Apparent Sidereal Time in degrees.
    public static func localSiderealTimeDegrees(
        for moment: CivilMoment, longitude: Double
    ) throws -> Double {
        let jd = try JulianDay.julianDay(for: moment)
        let dt = DeltaT.deltaT(decimalYear: moment.decimalYear)
        let tTT = JulianDay.julianCenturiesTT(jdUT: jd, deltaT: dt)
        let nut = Nutation.compute(julianCenturiesTT: tTT)
        let meanObl = Obliquity.meanObliquity(julianCenturiesTT: tTT)
        let trueObl = meanObl + nut.obliquity / 3600.0
        return SiderealTime.last(
            jdUT: jd, longitude: longitude,
            nutationLongitude: nut.longitude, trueObliquity: trueObl
        )
    }

    // --- Ascendant (requires coordinate) ---
    public static func ascendant(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) throws -> AscendantResult {
        try AscendantEngine.compute(for: moment, coordinate: coordinate)
    }

    // --- Individual body positions (apparent tropical longitude) ---
    public static func sunPosition(
        for moment: CivilMoment
    ) throws -> CelestialPosition {
        let (tau, t) = try timeParameters(for: moment)
        let nut = Nutation.compute(julianCenturiesTT: t)
        return applyingNutation(
            to: SolarPosition.compute(tau: tau, t: t),
            nutationArcsec: nut.longitude
        )
    }

    public static func moonPosition(
        for moment: CivilMoment
    ) throws -> CelestialPosition {
        let (_, t) = try timeParameters(for: moment)
        let nut = Nutation.compute(julianCenturiesTT: t)
        return applyingNutation(
            to: ELP2000.compute(julianCenturiesTT: t),
            nutationArcsec: nut.longitude
        )
    }

    public static func planetPosition(
        _ body: CelestialBody, for moment: CivilMoment
    ) throws -> CelestialPosition {
        switch body {
        case .sun: return try sunPosition(for: moment)
        case .moon: return try moonPosition(for: moment)
        default:
            let (tau, t) = try timeParameters(for: moment)
            let nut = Nutation.compute(julianCenturiesTT: t)
            return applyingNutation(
                to: PlanetaryPosition.compute(body, tau: tau),
                nutationArcsec: nut.longitude
            )
        }
    }

    // --- Batch (compute only what's requested) ---
    public static func natalPositions(
        for moment: CivilMoment,
        coordinate: GeoCoordinate? = nil,
        bodies: Set<CelestialBody> = [],
        includeAscendant: Bool = false
    ) throws -> NatalPositions {
        if includeAscendant && coordinate == nil {
            throw AstroError.missingCoordinateForAscendant
        }

        // Compute shared values once
        let jdUT = try JulianDay.julianDay(for: moment)
        let dt = DeltaT.deltaT(decimalYear: moment.decimalYear)
        let tau = JulianDay.julianMillenniaTT(jdUT: jdUT, deltaT: dt)
        let t = JulianDay.julianCenturiesTT(jdUT: jdUT, deltaT: dt)
        let nut = Nutation.compute(julianCenturiesTT: t)

        // Compute Earth position once (shared by Sun + all planets)
        let needsEarth = bodies.contains(.sun)
            || bodies.contains(where: { $0 != .sun && $0 != .moon })
        let earth = needsEarth ? VSOP87D.earthPosition(tau: tau) : nil

        // Ascendant (reuse nutation)
        var ascResult: AscendantResult?
        if includeAscendant, let coord = coordinate {
            try coord.validateForAscendant()
            let meanObl = Obliquity.meanObliquity(julianCenturiesTT: t)
            let trueObl = meanObl + nut.obliquity / 3600.0
            let lastDeg = SiderealTime.last(
                jdUT: jdUT, longitude: coord.longitude,
                nutationLongitude: nut.longitude, trueObliquity: trueObl
            )
            let ascLon = AscendantEngine.ascendantLongitude(
                lastDegrees: lastDeg,
                trueObliquityDegrees: trueObl,
                latitudeDegrees: coord.latitude
            )
            ascResult = AscendantResult(
                eclipticLongitude: ascLon,
                sign: ZodiacMapper.sign(forLongitude: ascLon),
                degreeInSign: ZodiacMapper.degreeInSign(longitude: ascLon),
                localSiderealTimeDegrees: lastDeg,
                julianDayUT: jdUT,
                trueObliquity: trueObl,
                isBoundaryCase: ZodiacMapper.isBoundaryCase(longitude: ascLon)
            )
        }

        // Body positions (reuse tau, t, nutation, earth)
        var positions: [CelestialBody: CelestialPosition] = [:]
        for body in bodies {
            let raw: CelestialPosition
            switch body {
            case .sun:
                raw = SolarPosition.compute(tau: tau, t: t, earth: earth!)
            case .moon:
                raw = ELP2000.compute(julianCenturiesTT: t)
            default:
                raw = PlanetaryPosition.compute(body, tau: tau, earth: earth!)
            }
            positions[body] = applyingNutation(to: raw, nutationArcsec: nut.longitude)
        }

        return NatalPositions(
            ascendant: ascResult,
            bodies: positions,
            julianDayUT: jdUT,
            deltaT: dt
        )
    }

    // --- Internal ---
    private static func timeParameters(
        for moment: CivilMoment
    ) throws -> (tau: Double, t: Double) {
        let jdUT = try JulianDay.julianDay(for: moment)
        let dt = DeltaT.deltaT(decimalYear: moment.decimalYear)
        let tau = JulianDay.julianMillenniaTT(jdUT: jdUT, deltaT: dt)
        let t = JulianDay.julianCenturiesTT(jdUT: jdUT, deltaT: dt)
        return (tau, t)
    }

    /// Apply nutation correction to convert from mean to apparent longitude.
    private static func applyingNutation(
        to position: CelestialPosition,
        nutationArcsec: Double
    ) -> CelestialPosition {
        let longitude = AngleMath.normalized(
            degrees: position.longitude + nutationArcsec / 3600.0
        )
        return CelestialPosition(
            body: position.body,
            longitude: longitude,
            latitude: position.latitude,
            sign: ZodiacMapper.sign(forLongitude: longitude),
            degreeInSign: ZodiacMapper.degreeInSign(longitude: longitude),
            isBoundaryCase: ZodiacMapper.isBoundaryCase(longitude: longitude)
        )
    }
}
