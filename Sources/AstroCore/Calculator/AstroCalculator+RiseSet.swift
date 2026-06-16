import Foundation

extension AstroCalculator {
    public enum MeridianTransitKind: Sendable, Hashable, Codable {
        case upper
        case lower
    }

    private static let diurnalSampleStepDays = 1.0 / 24.0 // 1 hour, rise/set bracket scan
    private static let transitSampleStepDays = 0.25
    private static let diurnalSlopeStepDays = 0.01
    private static let transitSiderealRateDegPerDay = 360.985647 // d(LAST)/dt, dominant transit slope
    private static let horizonRefractionDegrees = 0.5667 // 34′ standard horizontal refraction
    private static let diurnalValueTolerance = 1e-7
    private static let diurnalRootTolDays = 1e-9
    private static let diurnalSearchWindowDays = 1.0
    private static let earthEquatorialRadiusKm = 6378.137
    private static let auKm = 149597870.7
    private static let sunRadiusKm = 696000.0
    private static let moonRadiusKm = 1737.4

    private struct ApparentPlace {
        let rightAscension: Double
        let declination: Double
        let distanceAU: Double?
        let nutationLongitude: Double
        let trueObliquity: Double
    }

    // MARK: - JD-native apparent place (of date)

    private static func rawPosition(of body: CelestialBody, t: Double, tau: Double) -> RawCelestialPosition {
        switch body {
        case .sun: SolarPosition.compute(tau: tau, t: t)
        case .moon: ELP2000.compute(julianCenturiesTT: t)
        case .mercury, .venus, .mars, .jupiter, .saturn, .uranus, .neptune, .pluto:
            PlanetaryPosition.compute(body, tau: tau)
        case .meanNode, .trueNode, .lilith, .trueLilith:
            NodeLilith.position(body, julianCenturiesTT: t)
        }
    }

    private static func apparentPlace(of body: CelestialBody, julianDayTT jd: Double) -> ApparentPlace {
        let t = (jd - JulianDay.j2000) / 36525.0
        let tau = (jd - JulianDay.j2000) / 365250.0
        let nutation = Nutation.compute(julianCenturiesTT: t)
        let trueObliquity = Obliquity.meanObliquity(julianCenturiesTT: t) + nutation.obliquity / 3600.0
        let raw = rawPosition(of: body, t: t, tau: tau)
        let apparentLongitude = AngleMath.normalized(degrees: raw.longitude + nutation.longitude / 3600.0)
        let equatorial = EquatorialCoordinate.from(
            eclipticLongitudeDegrees: apparentLongitude,
            latitudeDegrees: raw.latitude,
            trueObliquityDegrees: trueObliquity
        )
        return ApparentPlace(
            rightAscension: equatorial.rightAscension,
            declination: equatorial.declination,
            distanceAU: raw.distance,
            nutationLongitude: nutation.longitude,
            trueObliquity: trueObliquity
        )
    }

    /// Apparent geocentric equatorial RA/Dec (of date) for a Julian Day in TT.
    public static func equatorial(of body: CelestialBody, julianDayTT jd: Double) -> EquatorialCoordinate {
        let place = apparentPlace(of: body, julianDayTT: jd)
        return EquatorialCoordinate(rightAscension: place.rightAscension, declination: place.declination)
    }

    // MARK: - Diurnal quantities at a UT instant

    private static func place(of body: CelestialBody, atJulianDayUT jdUT: Double) -> ApparentPlace {
        apparentPlace(of: body, julianDayTT: jdUT + deltaTSeconds(julianDayUT: jdUT) / 86400.0)
    }

    private static func localApparentSiderealTime(_ place: ApparentPlace, jdUT: Double, longitude: Double) -> Double {
        let gast = SiderealTime.gast(
            jdUT: jdUT,
            nutationLongitude: place.nutationLongitude,
            trueObliquity: place.trueObliquity
        )
        return AngleMath.normalized(degrees: gast + longitude)
    }

    private static func altitude(_ place: ApparentPlace, jdUT: Double, coordinate: GeoCoordinate) -> Double {
        Topocentric.horizontal(
            rightAscensionDegrees: place.rightAscension,
            declinationDegrees: place.declination,
            distanceAU: place.distanceAU,
            localApparentSiderealTimeDegrees: localApparentSiderealTime(place, jdUT: jdUT, longitude: coordinate.longitude),
            observerLatitudeDegrees: coordinate.latitude,
            observerElevationMeters: coordinate.elevation
        ).altitude
    }

    /// Topocentric geometric altitude (no refraction) of a body for a Julian Day in UT.
    public static func topocentricAltitudeDegrees(
        of body: CelestialBody, atJulianDayUT jd: Double, coordinate: GeoCoordinate
    ) -> Double {
        altitude(place(of: body, atJulianDayUT: jd), jdUT: jd, coordinate: coordinate)
    }

    /// Hour angle H = LAST − RA folded into (−180, 180]; zero at upper transit, ±180 at lower.
    public static func hourAngleDegrees(
        of body: CelestialBody, atJulianDayUT jd: Double, observerLongitude: Double
    ) -> Double {
        let place = place(of: body, atJulianDayUT: jd)
        let last = localApparentSiderealTime(place, jdUT: jd, longitude: observerLongitude)
        return wrappedDelta(last - place.rightAscension)
    }

    /// Angular radius (degrees) of the Sun/Moon disc; zero for point-like bodies.
    private static func semidiameterDegrees(of body: CelestialBody, distanceAU: Double?) -> Double {
        guard let distanceAU, distanceAU > 0 else { return 0.0 }
        let radiusKm: Double
        switch body {
        case .sun: radiusKm = sunRadiusKm
        case .moon: radiusKm = moonRadiusKm
        default: return 0.0
        }
        return AngleMath.toDegrees(Foundation.asin(min(1.0, radiusKm / (distanceAU * auKm))))
    }

    /// Standard altitude h0 of the body centre at the rise/set event. With refraction this is
    /// −(34′ + semidiameter); the topocentric path already carries parallax, so it is not re-added.
    /// Without refraction the centre meets the true horizon (h0 = 0).
    private static func standardAltitudeDegrees(
        of body: CelestialBody, distanceAU: Double?, applyRefraction: Bool
    ) -> Double {
        guard applyRefraction else { return 0.0 }
        return -(horizonRefractionDegrees + semidiameterDegrees(of: body, distanceAU: distanceAU))
    }

    /// Topocentric altitude minus the standard altitude h0; the rise/set residual (zero at the event).
    public static func altitudeAboveStandardDegrees(
        of body: CelestialBody, atJulianDayUT jd: Double, coordinate: GeoCoordinate,
        applyRefraction: Bool = true
    ) -> Double {
        let place = place(of: body, atJulianDayUT: jd)
        return altitude(place, jdUT: jd, coordinate: coordinate)
            - standardAltitudeDegrees(of: body, distanceAU: place.distanceAU, applyRefraction: applyRefraction)
    }

    // MARK: - Transit

    private static func transitTuning() -> RootSolver.Tuning {
        RootSolver.Tuning(
            step: transitSampleStepDays,
            valueTolerance: diurnalValueTolerance,
            stepTolerance: diurnalRootTolDays,
            wrapGuardDegrees: 180.0
        )
    }

    private static func transitResidual(
        of body: CelestialBody, observerLongitude: Double, target: Double
    ) -> (Double) -> Double {
        { jdUT in
            let place = place(of: body, atJulianDayUT: jdUT)
            let last = localApparentSiderealTime(place, jdUT: jdUT, longitude: observerLongitude)
            return wrappedDelta(last - place.rightAscension - target)
        }
    }

    /// JD(UT) of upper/lower culmination nearest the seed for a body at an observer longitude.
    public static func transitJulianDayUT(
        of body: CelestialBody, observerLongitude: Double,
        kind: MeridianTransitKind = .upper, nearJulianDayUT jd: Double
    ) -> Double? {
        let target = kind == .upper ? 0.0 : 180.0
        return RootSolver.nearestRoot(
            near: jd, window: diurnalSearchWindowDays, tuning: transitTuning(),
            value: transitResidual(of: body, observerLongitude: observerLongitude, target: target),
            slope: { _ in transitSiderealRateDegPerDay }
        )
    }

    /// All upper/lower transit JDs of a body in the closed UT interval, ordered by time.
    public static func transitJulianDaysUT(
        of body: CelestialBody, observerLongitude: Double, kind: MeridianTransitKind = .upper,
        fromJulianDayUT start: Double, throughJulianDayUT end: Double
    ) -> [Double] {
        let target = kind == .upper ? 0.0 : 180.0
        return RootSolver.roots(
            from: start, through: end, tuning: transitTuning(),
            value: transitResidual(of: body, observerLongitude: observerLongitude, target: target),
            slope: { _ in transitSiderealRateDegPerDay }
        )
    }

    // MARK: - Rise / set

    private static func diurnalTuning() -> RootSolver.Tuning {
        RootSolver.Tuning(
            step: diurnalSampleStepDays,
            valueTolerance: diurnalValueTolerance,
            stepTolerance: diurnalRootTolDays
        )
    }

    /// Altitude crossings of the standard altitude in [start, end], each tagged rising / setting by
    /// the sign of the altitude rate at the crossing.
    private static func altitudeCrossings(
        of body: CelestialBody, coordinate: GeoCoordinate,
        from start: Double, through end: Double, applyRefraction: Bool
    ) -> [(julianDayUT: Double, rising: Bool)] {
        let value: (Double) -> Double = {
            altitudeAboveStandardDegrees(of: body, atJulianDayUT: $0, coordinate: coordinate, applyRefraction: applyRefraction)
        }
        let slope: (Double) -> Double = {
            (value($0 + diurnalSlopeStepDays) - value($0 - diurnalSlopeStepDays)) / (2.0 * diurnalSlopeStepDays)
        }
        return RootSolver.roots(
            from: start, through: end, tuning: diurnalTuning(), value: value, slope: slope
        ).map { (julianDayUT: $0, rising: slope($0) > 0) }
    }

    private static func nearestCrossing(
        of body: CelestialBody, coordinate: GeoCoordinate, near jd: Double,
        rising: Bool, applyRefraction: Bool
    ) -> Double? {
        altitudeCrossings(
            of: body, coordinate: coordinate,
            from: jd - diurnalSearchWindowDays, through: jd + diurnalSearchWindowDays,
            applyRefraction: applyRefraction
        )
        .filter { $0.rising == rising }
        .min(by: { abs($0.julianDayUT - jd) < abs($1.julianDayUT - jd) })?
        .julianDayUT
    }

    /// JD(UT) of rise nearest the seed; nil when the body is circumpolar / never rises in the window.
    public static func riseJulianDayUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        nearJulianDayUT jd: Double, applyRefraction: Bool = true
    ) -> Double? {
        nearestCrossing(of: body, coordinate: coordinate, near: jd, rising: true, applyRefraction: applyRefraction)
    }

    /// JD(UT) of set nearest the seed; nil when the body is circumpolar / never rises in the window.
    public static func setJulianDayUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        nearJulianDayUT jd: Double, applyRefraction: Bool = true
    ) -> Double? {
        nearestCrossing(of: body, coordinate: coordinate, near: jd, rising: false, applyRefraction: applyRefraction)
    }

    /// All rise JDs of a body in the closed UT interval, ordered by time.
    public static func riseJulianDaysUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        fromJulianDayUT start: Double, throughJulianDayUT end: Double, applyRefraction: Bool = true
    ) -> [Double] {
        riseSetCrossingsUT(
            of: body, coordinate: coordinate,
            fromJulianDayUT: start, throughJulianDayUT: end,
            applyRefraction: applyRefraction
        )
        .filter(\.rising)
        .map(\.julianDayUT)
    }

    /// All set JDs of a body in the closed UT interval, ordered by time.
    public static func setJulianDaysUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        fromJulianDayUT start: Double, throughJulianDayUT end: Double, applyRefraction: Bool = true
    ) -> [Double] {
        riseSetCrossingsUT(
            of: body, coordinate: coordinate,
            fromJulianDayUT: start, throughJulianDayUT: end,
            applyRefraction: applyRefraction
        )
        .filter { !$0.rising }
        .map(\.julianDayUT)
    }

    /// All rise/set crossings in the closed UT interval, ordered by time and tagged by altitude slope.
    package static func riseSetCrossingsUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        fromJulianDayUT start: Double, throughJulianDayUT end: Double, applyRefraction: Bool = true
    ) -> [(julianDayUT: Double, rising: Bool)] {
        altitudeCrossings(
            of: body, coordinate: coordinate,
            from: start, through: end,
            applyRefraction: applyRefraction
        )
    }

    /// JDs where the body's geometric altitude crosses an explicit target (e.g. twilight
    /// depressions), `rising` selecting ascending vs descending crossings. Unlike rise/set this uses
    /// a fixed target altitude rather than the body's distance-dependent standard altitude.
    public static func altitudeCrossingsUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        targetAltitudeDegrees target: Double, rising: Bool,
        fromJulianDayUT start: Double, throughJulianDayUT end: Double
    ) -> [Double] {
        altitudeCrossingEventsUT(
            of: body, coordinate: coordinate,
            targetAltitudeDegrees: target,
            fromJulianDayUT: start, throughJulianDayUT: end
        )
        .filter { $0.rising == rising }
        .map(\.julianDayUT)
    }

    /// All explicit target-altitude crossings in the closed UT interval, ordered and tagged by slope.
    package static func altitudeCrossingEventsUT(
        of body: CelestialBody, coordinate: GeoCoordinate,
        targetAltitudeDegrees target: Double,
        fromJulianDayUT start: Double, throughJulianDayUT end: Double
    ) -> [(julianDayUT: Double, rising: Bool)] {
        let value: (Double) -> Double = {
            topocentricAltitudeDegrees(of: body, atJulianDayUT: $0, coordinate: coordinate) - target
        }
        let slope: (Double) -> Double = {
            (value($0 + diurnalSlopeStepDays) - value($0 - diurnalSlopeStepDays)) / (2.0 * diurnalSlopeStepDays)
        }
        return RootSolver.roots(from: start, through: end, tuning: diurnalTuning(), value: value, slope: slope)
            .map { (julianDayUT: $0, rising: slope($0) > 0) }
    }
}
