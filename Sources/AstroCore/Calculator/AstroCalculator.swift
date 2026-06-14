import Foundation

/// Single public entry point for all astronomical calculations
public enum AstroCalculator {
    private static let speedStepDays = 0.25

    /// --- Low-level (stable API) ---
    public static func julianDayUT(for moment: CivilMoment) -> Double {
        moment.julianDayUT
    }

    /// Apparent geocentric ecliptic longitude in degrees [0, 360)
    /// for a Julian Day in TT.
    public static func eclipticLongitude(
        of body: CelestialBody,
        julianDayTT jd: Double
    ) -> Double {
        let t = (jd - JulianDay.j2000) / 36525.0
        let tau = (jd - JulianDay.j2000) / 365250.0
        let nutationArcsec = Nutation.compute(julianCenturiesTT: t).longitude
        let raw = switch body {
        case .sun:
            SolarPosition.compute(tau: tau, t: t)
        case .moon:
            ELP2000.compute(julianCenturiesTT: t)
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
            PlanetaryPosition.compute(body, tau: tau)
        }
        return AngleMath.normalized(degrees: raw.longitude + nutationArcsec / 3600.0)
    }

    /// Delta T (TT - UT) in seconds for a Julian Day in UT.
    public static func deltaTSeconds(julianDayUT jd: Double) -> Double {
        let decimalYear = 2000.0 + (jd - JulianDay.j2000) / 365.25
        return DeltaT.deltaT(decimalYear: decimalYear)
    }

    /// Apparent geocentric ecliptic longitude for a Julian Day in UT.
    public static func eclipticLongitude(
        of body: CelestialBody,
        julianDayUT jd: Double
    ) -> Double {
        eclipticLongitude(
            of: body,
            julianDayTT: jd + deltaTSeconds(julianDayUT: jd) / 86400.0
        )
    }

    /// Daily longitude motion in degrees per day for a Julian Day in TT.
    public static func longitudeSpeed(
        of body: CelestialBody,
        julianDayTT jd: Double
    ) -> Double {
        let lo = eclipticLongitude(of: body, julianDayTT: jd - speedStepDays)
        let hi = eclipticLongitude(of: body, julianDayTT: jd + speedStepDays)
        return longitudeSpeed(fromLower: lo, upper: hi)
    }

    /// Returns Local Apparent Sidereal Time in degrees.
    public static func localSiderealTimeDegrees(
        for moment: CivilMoment, longitude: Double
    ) -> Double {
        moment.localApparentSiderealTime(longitude: longitude)
    }

    /// Ascendant ecliptic longitude (no zodiac). Throws for undefined high latitudes.
    public static func ascendantLongitude(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) throws(AstroError) -> Double {
        try coordinate.validateForAscendant()
        let last = moment.localApparentSiderealTime(longitude: coordinate.longitude)
        return Axis.ascendantLongitude(
            lastDegrees: last,
            trueObliquityDegrees: moment.trueObliquity,
            latitudeDegrees: coordinate.latitude
        )
    }

    /// Midheaven ecliptic longitude (no zodiac). Defined at all latitudes.
    public static func midheavenLongitude(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) -> Double {
        let last = moment.localApparentSiderealTime(longitude: coordinate.longitude)
        return Axis.midheavenLongitude(
            lastDegrees: last,
            trueObliquityDegrees: moment.trueObliquity
        )
    }

    /// --- Individual body positions (apparent tropical longitude) ---
    public static func sunPosition(
        for moment: CivilMoment
    ) -> CelestialPosition {
        let (tau, t) = timeParameters(for: moment)
        return makePosition(
            from: SolarPosition.compute(tau: tau, t: t),
            nutationArcsec: moment.nutationLongitude
        )
    }

    public static func moonPosition(
        for moment: CivilMoment
    ) -> CelestialPosition {
        let (_, t) = timeParameters(for: moment)
        return makePosition(
            from: ELP2000.compute(julianCenturiesTT: t),
            nutationArcsec: moment.nutationLongitude
        )
    }

    public static func planetPosition(
        _ body: CelestialBody, for moment: CivilMoment
    ) -> CelestialPosition {
        switch body {
        case .sun: return sunPosition(for: moment)
        case .moon: return moonPosition(for: moment)
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
            let (tau, _) = timeParameters(for: moment)
            return makePosition(
                from: PlanetaryPosition.compute(body, tau: tau),
                nutationArcsec: moment.nutationLongitude
            )
        }
    }

    public static func celestialState(
        _ body: CelestialBody, for moment: CivilMoment
    ) -> CelestialState {
        let position = planetPosition(body, for: moment)
        return makeState(
            from: position,
            julianDayTT: julianDayTT(for: moment)
        )
    }

    /// --- Batch (neutral, no ascendant / zodiac) ---
    public static func positions(
        of bodies: Set<CelestialBody>,
        at moment: CivilMoment
    ) -> [CelestialBody: CelestialPosition] {
        let tau = moment.julianMillenniaTT
        let t = moment.julianCenturiesTT
        let nutationLongitude = moment.nutationLongitude

        // Compute Earth position once (shared by Sun + all planets)
        let needsEarth = bodies.contains(.sun)
            || bodies.contains(where: { $0 != .sun && $0 != .moon })
        let earth = needsEarth ? VSOP87D.earthPosition(tau: tau) : nil
        let earthMotion = earth.map { PlanetaryPosition.earthMotion(tau: tau, earth: $0) }

        var result: [CelestialBody: CelestialPosition] = [:]
        result.reserveCapacity(bodies.count)
        for body in bodies {
            let raw: RawCelestialPosition
            switch body {
            case .sun:
                let e = earth ?? VSOP87D.earthPosition(tau: tau)
                raw = SolarPosition.compute(tau: tau, t: t, earth: e)
            case .moon:
                raw = ELP2000.compute(julianCenturiesTT: t)
            case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
                let motion = earthMotion ?? PlanetaryPosition.earthMotion(
                    tau: tau,
                    earth: VSOP87D.earthPosition(tau: tau)
                )
                raw = PlanetaryPosition.compute(body, tau: tau, earthMotion: motion)
            }
            result[body] = makePosition(from: raw, nutationArcsec: nutationLongitude)
        }
        return result
    }

    public static func states(
        of bodies: Set<CelestialBody>,
        at moment: CivilMoment
    ) -> [CelestialBody: CelestialState] {
        let base = positions(of: bodies, at: moment)
        let jdTT = julianDayTT(for: moment)
        let lower = eclipticLongitudes(of: bodies, julianDayTT: jdTT - speedStepDays)
        let upper = eclipticLongitudes(of: bodies, julianDayTT: jdTT + speedStepDays)

        var result: [CelestialBody: CelestialState] = [:]
        result.reserveCapacity(bodies.count)
        for body in bodies {
            guard let position = base[body],
                  let lowerLongitude = lower[body],
                  let upperLongitude = upper[body]
            else { continue }
            result[body] = CelestialState(
                body: position.body,
                longitude: position.longitude,
                latitude: position.latitude,
                speed: longitudeSpeed(fromLower: lowerLongitude, upper: upperLongitude)
            )
        }
        return result
    }

    /// --- Internal ---
    private static func timeParameters(
        for moment: CivilMoment
    ) -> (tau: Double, t: Double) {
        (moment.julianMillenniaTT, moment.julianCenturiesTT)
    }

    private static func julianDayTT(for moment: CivilMoment) -> Double {
        moment.julianDayUT + moment.deltaT / 86400.0
    }

    private static func eclipticLongitudes(
        of bodies: Set<CelestialBody>,
        julianDayTT jd: Double
    ) -> [CelestialBody: Double] {
        let t = (jd - JulianDay.j2000) / 36525.0
        let tau = (jd - JulianDay.j2000) / 365250.0
        let nutationArcsec = Nutation.compute(julianCenturiesTT: t).longitude
        let needsEarth = bodies.contains(.sun)
            || bodies.contains(where: { $0 != .sun && $0 != .moon })
        let earth = needsEarth ? VSOP87D.earthPosition(tau: tau) : nil
        let earthMotion = earth.map { PlanetaryPosition.earthMotion(tau: tau, earth: $0) }

        var longitudes: [CelestialBody: Double] = [:]
        longitudes.reserveCapacity(bodies.count)
        for body in bodies {
            let raw: RawCelestialPosition
            switch body {
            case .sun:
                let e = earth ?? VSOP87D.earthPosition(tau: tau)
                raw = SolarPosition.compute(tau: tau, t: t, earth: e)
            case .moon:
                raw = ELP2000.compute(julianCenturiesTT: t)
            case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
                let motion = earthMotion ?? PlanetaryPosition.earthMotion(
                    tau: tau,
                    earth: VSOP87D.earthPosition(tau: tau)
                )
                raw = PlanetaryPosition.compute(
                    body,
                    tau: tau,
                    earthMotion: motion
                )
            }
            longitudes[body] = apparentLongitude(
                from: raw,
                nutationArcsec: nutationArcsec
            )
        }
        return longitudes
    }

    /// Apply nutation to produce the lightweight public position.
    @inline(__always)
    private static func makePosition(
        from raw: RawCelestialPosition,
        nutationArcsec: Double
    ) -> CelestialPosition {
        let longitude = apparentLongitude(from: raw, nutationArcsec: nutationArcsec)
        return CelestialPosition(
            body: raw.body,
            longitude: longitude,
            latitude: raw.latitude
        )
    }

    private static func makeState(
        from position: CelestialPosition,
        julianDayTT jd: Double
    ) -> CelestialState {
        CelestialState(
            body: position.body,
            longitude: position.longitude,
            latitude: position.latitude,
            speed: longitudeSpeed(of: position.body, julianDayTT: jd)
        )
    }

    private static func apparentLongitude(
        from raw: RawCelestialPosition,
        nutationArcsec: Double
    ) -> Double {
        AngleMath.normalized(degrees: raw.longitude + nutationArcsec / 3600.0)
    }

    private static func longitudeSpeed(
        fromLower lo: Double,
        upper hi: Double
    ) -> Double {
        var diff = hi - lo
        if diff > 180.0 { diff -= 360.0 }
        if diff < -180.0 { diff += 360.0 }
        return diff / (2.0 * speedStepDays)
    }
}
