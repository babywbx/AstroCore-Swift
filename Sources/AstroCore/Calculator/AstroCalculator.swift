import Foundation

/// Single public entry point for all astronomical calculations
public enum AstroCalculator {
    static let speedStepDays = 0.25
    private static let supportedYearRange = 1800...2100

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
        guard isSupportedJulianDay(jd) else { return .nan }
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
        case .meanNode, .trueNode, .lilith, .trueLilith:
            NodeLilith.position(body, julianCenturiesTT: t)
        }
        return AngleMath.normalized(degrees: raw.longitude + nutationArcsec / 3600.0)
    }

    /// Delta T (TT - UT) in seconds for a Julian Day in UT.
    public static func deltaTSeconds(julianDayUT jd: Double) -> Double {
        guard isSupportedJulianDay(jd) else { return .nan }
        let decimalYear = 2000.0 + (jd - JulianDay.j2000) / 365.25
        return DeltaT.deltaT(decimalYear: decimalYear)
    }

    /// UT Julian Day for a TT Julian Day, inverting ΔT (jdUT = jdTT − ΔT(jdUT)/86400).
    public static func julianDayUT(fromJulianDayTT jdTT: Double) -> Double {
        guard isSupportedJulianDay(jdTT) else { return .nan }
        var jdUT = jdTT
        for _ in 0..<8 {
            let deltaT = deltaTSeconds(julianDayUT: jdUT)
            guard deltaT.isFinite else { return .nan }
            let next = jdTT - deltaT / 86400.0
            if abs(next - jdUT) < 1e-9 { return next }
            jdUT = next
        }
        return jdUT
    }

    /// Apparent geocentric ecliptic longitude for a Julian Day in UT.
    public static func eclipticLongitude(
        of body: CelestialBody,
        julianDayUT jd: Double
    ) -> Double {
        guard isSupportedJulianDay(jd) else { return .nan }
        return eclipticLongitude(
            of: body,
            julianDayTT: jd + deltaTSeconds(julianDayUT: jd) / 86400.0
        )
    }

    /// Daily longitude motion in degrees per day for a Julian Day in TT.
    public static func longitudeSpeed(
        of body: CelestialBody,
        julianDayTT jd: Double
    ) -> Double {
        guard isSupportedJulianDay(jd - speedStepDays),
              isSupportedJulianDay(jd + speedStepDays)
        else { return .nan }
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
        case .meanNode, .trueNode, .lilith, .trueLilith:
            let (_, t) = timeParameters(for: moment)
            return makePosition(
                from: NodeLilith.position(body, julianCenturiesTT: t),
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

    /// --- Derived coordinate frames (apparent, of date) ---

    /// Apparent geocentric equatorial RA/Dec (of date) for any body, computed by
    /// rotating the apparent ecliptic position by the true obliquity.
    public static func equatorial(
        of body: CelestialBody, at moment: CivilMoment
    ) -> EquatorialCoordinate {
        let position = planetPosition(body, for: moment)
        return EquatorialCoordinate.from(
            eclipticLongitudeDegrees: position.longitude,
            latitudeDegrees: position.latitude,
            trueObliquityDegrees: moment.trueObliquity
        )
    }

    /// Geometric heliocentric ecliptic position (mean equinox & ecliptic of date) for planets.
    /// nil for the Sun (origin), Moon (geocentric-only) and computed points.
    public static func heliocentric(
        of body: CelestialBody, at moment: CivilMoment
    ) -> EclipticCoordinate? {
        let tau = moment.julianMillenniaTT
        let helio: VSOP87D.SphericalPosition
        switch body {
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune:
            helio = VSOP87D.planetPosition(body, tau: tau)
        case .pluto:
            helio = PlutoPosition.heliocentric(tau: tau)
        case .sun, .moon, .meanNode, .trueNode, .lilith, .trueLilith:
            return nil
        }
        return EclipticCoordinate(
            longitude: AngleMath.normalized(degrees: AngleMath.toDegrees(helio.longitude)),
            latitude: AngleMath.toDegrees(helio.latitude),
            distance: helio.radius
        )
    }

    /// Topocentric geometric horizontal coordinates (alt/az, no refraction) for an observer.
    /// Diurnal parallax is applied for distance-bearing bodies; computed points get geometric alt/az.
    public static func horizontal(
        of body: CelestialBody, at moment: CivilMoment, observer: GeoCoordinate
    ) -> HorizontalCoordinate {
        let position = planetPosition(body, for: moment)
        let equatorial = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: position.longitude,
            latitudeDegrees: position.latitude,
            trueObliquityDegrees: moment.trueObliquity
        )
        return Topocentric.horizontal(
            rightAscensionDegrees: equatorial.rightAscension,
            declinationDegrees: equatorial.declination,
            distanceAU: position.distance,
            localApparentSiderealTimeDegrees: moment.localApparentSiderealTime(
                longitude: observer.longitude
            ),
            observerLatitudeDegrees: observer.latitude,
            observerElevationMeters: observer.elevation
        )
    }

    /// Illumination (phase angle, illuminated fraction, elongation) from Sun-body-Earth geometry.
    /// nil for the Sun and for computed points (which have no geocentric distance).
    public static func illumination(
        of body: CelestialBody, at moment: CivilMoment
    ) -> Illumination? {
        switch body {
        case .sun, .meanNode, .trueNode, .lilith, .trueLilith:
            return nil
        case .moon, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
            break
        }

        let (tau, t) = timeParameters(for: moment)
        let nutationLongitude = moment.nutationLongitude
        let earth = VSOP87D.earthPosition(tau: tau)
        let sun = makePosition(
            from: SolarPosition.compute(tau: tau, t: t, earth: earth),
            nutationArcsec: nutationLongitude
        )
        let targetRaw: RawCelestialPosition
        switch body {
        case .moon:
            targetRaw = ELP2000.compute(julianCenturiesTT: t)
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
            targetRaw = PlanetaryPosition.compute(
                body,
                tau: tau,
                earthMotion: PlanetaryPosition.earthMotion(tau: tau, earth: earth)
            )
        case .sun, .meanNode, .trueNode, .lilith, .trueLilith:
            return nil
        }
        let target = makePosition(from: targetRaw, nutationArcsec: nutationLongitude)
        guard let earthSun = sun.distance, let geocentric = target.distance else { return nil }

        let (sinLatT, cosLatT) = TrigDeg.sincos(target.latitude)
        let (sinLatS, cosLatS) = TrigDeg.sincos(sun.latitude)
        let cosElongation = min(1.0, max(-1.0,
                                         sinLatT * sinLatS + cosLatT * cosLatS * TrigDeg.cos(target.longitude - sun.longitude)))
        let elongation = TrigDeg.acos(cosElongation)

        let (sinPsi, cosPsi) = TrigDeg.sincos(elongation)
        let phaseAngle = AngleMath.toDegrees(Foundation.atan2(
            earthSun * sinPsi, geocentric - earthSun * cosPsi
        ))
        let illuminatedFraction = (1.0 + TrigDeg.cos(phaseAngle)) / 2.0
        return Illumination(
            phaseAngle: phaseAngle,
            illuminatedFraction: illuminatedFraction,
            elongation: elongation
        )
    }

    /// Equation of time in minutes (apparent solar time − mean solar time) for a Julian Day in UT.
    /// True solar time = mean solar time + equationOfTime + (longitudeDegrees × 4) minutes (east positive).
    public static func equationOfTime(julianDayUT jd: Double) -> Double {
        guard isSupportedJulianDay(jd) else { return .nan }
        let jdTT = jd + deltaTSeconds(julianDayUT: jd) / 86400.0
        let t = (jdTT - JulianDay.j2000) / 36525.0
        let tau = (jdTT - JulianDay.j2000) / 365250.0
        // Sun's geometric mean longitude, degrees.
        let meanLongitude = AngleMath.normalized(degrees:
            280.4664567 + 360007.6982779 * tau + 0.03032028 * tau * tau
                + tau * tau * tau / 49931.0
                - tau * tau * tau * tau / 15300.0
                - tau * tau * tau * tau * tau / 2000000.0)
        let nutation = Nutation.compute(julianCenturiesTT: t)
        let trueObliquity = Obliquity.meanObliquity(julianCenturiesTT: t) + nutation.obliquity / 3600.0
        let sun = SolarPosition.compute(tau: tau, t: t)
        let apparentLongitude = AngleMath.normalized(degrees: sun.longitude + nutation.longitude / 3600.0)
        let apparentRA = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: apparentLongitude,
            latitudeDegrees: sun.latitude,
            trueObliquityDegrees: trueObliquity
        ).rightAscension
        var degrees = meanLongitude - apparentRA + (nutation.longitude / 3600.0) * TrigDeg.cos(trueObliquity)
        degrees = degrees.truncatingRemainder(dividingBy: 360.0)
        if degrees > 180.0 { degrees -= 360.0 } else if degrees < -180.0 { degrees += 360.0 }
        return degrees * 4.0
    }

    /// --- Batch (neutral, no ascendant / zodiac) ---
    public static func positions(
        of bodies: Set<CelestialBody>,
        at moment: CivilMoment
    ) -> [CelestialBody: CelestialPosition] {
        guard !bodies.isEmpty else { return [:] }

        let tau = moment.julianMillenniaTT
        let t = moment.julianCenturiesTT
        let nutationLongitude = moment.nutationLongitude

        // Compute Earth position once (shared by Sun + all planets)
        let needsEarth = needsEarthPosition(for: bodies)
        let earth = needsEarth ? VSOP87D.earthPosition(tau: tau) : nil
        let earthMotion = needsEarthMotion(for: bodies) ? earth.map { PlanetaryPosition.earthMotion(tau: tau, earth: $0) } : nil

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
            case .meanNode, .trueNode, .lilith, .trueLilith:
                raw = NodeLilith.position(body, julianCenturiesTT: t)
            }
            result[body] = makePosition(from: raw, nutationArcsec: nutationLongitude)
        }
        return result
    }

    public static func states(
        of bodies: Set<CelestialBody>,
        at moment: CivilMoment
    ) -> [CelestialBody: CelestialState] {
        guard !bodies.isEmpty else { return [:] }

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
                distance: position.distance,
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

    private static func needsEarthPosition(for bodies: Set<CelestialBody>) -> Bool {
        bodies.contains { body in
            switch body {
            case .sun, .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
                true
            case .moon, .meanNode, .trueNode, .lilith, .trueLilith:
                false
            }
        }
    }

    private static func needsEarthMotion(for bodies: Set<CelestialBody>) -> Bool {
        bodies.contains { body in
            switch body {
            case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
                true
            case .sun, .moon, .meanNode, .trueNode, .lilith, .trueLilith:
                false
            }
        }
    }

    private static func eclipticLongitudes(
        of bodies: Set<CelestialBody>,
        julianDayTT jd: Double
    ) -> [CelestialBody: Double] {
        guard !bodies.isEmpty else { return [:] }
        guard isSupportedJulianDay(jd) else { return [:] }

        let t = (jd - JulianDay.j2000) / 36525.0
        let tau = (jd - JulianDay.j2000) / 365250.0
        let nutationArcsec = Nutation.compute(julianCenturiesTT: t).longitude
        let needsEarth = needsEarthPosition(for: bodies)
        let earth = needsEarth ? VSOP87D.earthPosition(tau: tau) : nil
        let earthMotion = needsEarthMotion(for: bodies) ? earth.map { PlanetaryPosition.earthMotion(tau: tau, earth: $0) } : nil

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
            case .meanNode, .trueNode, .lilith, .trueLilith:
                raw = NodeLilith.position(body, julianCenturiesTT: t)
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
            latitude: raw.latitude,
            distance: raw.distance
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
            distance: position.distance,
            speed: longitudeSpeed(of: position.body, julianDayTT: jd)
        )
    }

    private static func apparentLongitude(
        from raw: RawCelestialPosition,
        nutationArcsec: Double
    ) -> Double {
        AngleMath.normalized(degrees: raw.longitude + nutationArcsec / 3600.0)
    }

    static func longitudeSpeed(
        fromLower lo: Double,
        upper hi: Double
    ) -> Double {
        guard lo.isFinite, hi.isFinite else { return .nan }
        var diff = hi - lo
        if diff > 180.0 { diff -= 360.0 }
        if diff < -180.0 { diff += 360.0 }
        return diff / (2.0 * speedStepDays)
    }

    static func isSupportedJulianDay(_ julianDay: Double) -> Bool {
        guard julianDay.isFinite else { return false }
        let civil = JulianDay.calendarDate(julianDay: julianDay)
        return supportedYearRange.contains(civil.year)
    }
}
