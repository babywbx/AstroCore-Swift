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

    // --- Ascendant (Phase 2) ---
    public static func ascendant(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) throws -> AscendantResult {
        try AscendantEngine.compute(for: moment, coordinate: coordinate)
    }

    // --- Individual body positions (Phase 3) ---
    public static func sunPosition(
        for moment: CivilMoment
    ) throws -> CelestialPosition {
        fatalError("Phase 3: Not yet implemented")
    }

    public static func moonPosition(
        for moment: CivilMoment
    ) throws -> CelestialPosition {
        fatalError("Phase 3: Not yet implemented")
    }

    public static func planetPosition(
        _ body: CelestialBody, for moment: CivilMoment
    ) throws -> CelestialPosition {
        fatalError("Phase 3: Not yet implemented")
    }

    // --- Batch ---
    public static func natalPositions(
        for moment: CivilMoment,
        coordinate: GeoCoordinate? = nil,
        bodies: Set<CelestialBody> = [],
        includeAscendant: Bool = false
    ) throws -> NatalPositions {
        fatalError("Phase 3: Not yet implemented")
    }
}
