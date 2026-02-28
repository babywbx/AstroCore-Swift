import Foundation

// Single public entry point for all astronomical calculations
public enum AstroCalculator {
    // --- Low-level (stable API) ---
    public static func julianDayUT(for moment: CivilMoment) throws -> Double {
        moment.julianDayUT
    }

    /// Returns Local Apparent Sidereal Time in degrees.
    public static func localSiderealTimeDegrees(
        for moment: CivilMoment, longitude: Double
    ) throws -> Double {
        moment.localApparentSiderealTime(longitude: longitude)
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
        let (tau, t) = timeParameters(for: moment)
        return applyingNutation(
            to: SolarPosition.compute(tau: tau, t: t),
            nutationArcsec: moment.nutationLongitude
        )
    }

    public static func moonPosition(
        for moment: CivilMoment
    ) throws -> CelestialPosition {
        let (_, t) = timeParameters(for: moment)
        return applyingNutation(
            to: ELP2000.compute(julianCenturiesTT: t),
            nutationArcsec: moment.nutationLongitude
        )
    }

    public static func planetPosition(
        _ body: CelestialBody, for moment: CivilMoment
    ) throws -> CelestialPosition {
        switch body {
        case .sun: return try sunPosition(for: moment)
        case .moon: return try moonPosition(for: moment)
        default:
            let (tau, _) = timeParameters(for: moment)
            return applyingNutation(
                to: PlanetaryPosition.compute(body, tau: tau),
                nutationArcsec: moment.nutationLongitude
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
        let jdUT = moment.julianDayUT
        let dt = moment.deltaT
        let tau = moment.julianMillenniaTT
        let t = moment.julianCenturiesTT
        let nutationLongitude = moment.nutationLongitude

        // Compute Earth position once (shared by Sun + all planets)
        let needsEarth = bodies.contains(.sun)
            || bodies.contains(where: { $0 != .sun && $0 != .moon })
        let earth = needsEarth ? VSOP87D.earthPosition(tau: tau) : nil
        let earthRect = earth.map { PlanetaryPosition.rectangular(from: $0) }

        // Ascendant (reuse nutation)
        var ascResult: AscendantResult?
        if includeAscendant, let coord = coordinate {
            try coord.validateForAscendant()
            let trueObl = moment.trueObliquity
            let lastDeg = moment.localApparentSiderealTime(longitude: coord.longitude)
            let ascLon = AscendantEngine.ascendantLongitude(
                lastDegrees: lastDeg,
                trueObliquityDegrees: trueObl,
                latitudeDegrees: coord.latitude
            )
            let zodiac = ZodiacMapper.details(forNormalizedLongitude: ascLon)
            ascResult = AscendantResult(
                eclipticLongitude: ascLon,
                sign: zodiac.sign,
                degreeInSign: zodiac.degreeInSign,
                localSiderealTimeDegrees: lastDeg,
                julianDayUT: jdUT,
                trueObliquity: trueObl,
                isBoundaryCase: zodiac.isBoundaryCase
            )
        }

        // Body positions (reuse tau, t, nutation, earth)
        var positions: [CelestialBody: CelestialPosition] = [:]
        positions.reserveCapacity(bodies.count)
        for body in bodies {
            let raw: RawCelestialPosition
            switch body {
            case .sun:
                raw = SolarPosition.compute(tau: tau, t: t, earth: earth!)
            case .moon:
                raw = ELP2000.compute(julianCenturiesTT: t)
            default:
                raw = PlanetaryPosition.compute(body, tau: tau, earthRect: earthRect!)
            }
            positions[body] = applyingNutation(to: raw, nutationArcsec: nutationLongitude)
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
    ) -> (tau: Double, t: Double) {
        (moment.julianMillenniaTT, moment.julianCenturiesTT)
    }

    /// Apply nutation correction to convert from mean to apparent longitude.
    @inline(__always)
    private static func applyingNutation(
        to position: RawCelestialPosition,
        nutationArcsec: Double
    ) -> CelestialPosition {
        let longitude = AngleMath.normalized(
            degrees: position.longitude + nutationArcsec / 3600.0
        )
        let zodiac = ZodiacMapper.details(forNormalizedLongitude: longitude)
        return CelestialPosition(
            body: position.body,
            longitude: longitude,
            latitude: position.latitude,
            sign: zodiac.sign,
            degreeInSign: zodiac.degreeInSign,
            isBoundaryCase: zodiac.isBoundaryCase
        )
    }
}
