import Foundation

// Single public entry point for all astronomical calculations
public enum AstroCalculator {
    // --- Low-level (stable API) ---
    public static func julianDayUT(for moment: CivilMoment) throws -> Double {
        try JulianDay.julianDay(for: moment)
    }

    /// Returns local sidereal time in degrees.
    /// Phase 1: returns LMST. Upgraded to LAST once nutation ships.
    public static func localSiderealTimeDegrees(
        for moment: CivilMoment, longitude: Double
    ) throws -> Double {
        let jd = try JulianDay.julianDay(for: moment)
        return AngleMath.normalized(
            degrees: SiderealTime.gmst(jdUT: jd) + longitude
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
