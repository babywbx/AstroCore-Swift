import AstroCore
import Foundation

/// Public entry point for astrology computations layered on AstroCore.
public enum AstrologyCalculator {
    /// Ascendant with zodiac sign.
    public static func ascendant(
        for moment: CivilMoment, coordinate: GeoCoordinate
    ) throws(AstrologyError) -> AscendantResult {
        let ascLon: Double
        do {
            ascLon = try AstroCalculator.ascendantLongitude(for: moment, coordinate: coordinate)
        } catch {
            throw AstrologyError.core(error)
        }
        return ascendantResult(eclipticLongitude: ascLon)
    }

    private static func ascendantResult(eclipticLongitude ascLon: Double) -> AscendantResult {
        let zodiac = ZodiacMapper.details(forNormalizedLongitude: ascLon)
        return AscendantResult(
            eclipticLongitude: ascLon,
            sign: zodiac.sign,
            degreeInSign: zodiac.degreeInSign,
            isBoundaryCase: zodiac.isBoundaryCase
        )
    }

    /// House cusps and angles.
    public static func houses(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        system: HouseSystem = .placidus,
        polarFallback: PolarFallback = .porphyry
    ) throws(AstrologyError) -> HouseResult {
        try HouseEngine.compute(
            for: moment, coordinate: coordinate,
            system: system, polarFallback: polarFallback
        )
    }

    /// 36 Gauquelin sectors.
    public static func gauquelinSectors(
        for moment: CivilMoment,
        coordinate: GeoCoordinate
    ) throws(AstrologyError) -> GauquelinResult {
        try GauquelinEngine.compute(for: moment, coordinate: coordinate)
    }

    /// Batch body positions plus optional zodiac ascendant.
    public static func natalPositions(
        for moment: CivilMoment,
        coordinate: GeoCoordinate? = nil,
        bodies: Set<CelestialBody> = [],
        includeAscendant: Bool = false
    ) throws(AstrologyError) -> NatalPositions {
        var asc: AscendantResult?
        if includeAscendant {
            guard let coordinate else { throw .missingCoordinateForAscendant }
            asc = try ascendant(for: moment, coordinate: coordinate)
        }
        return NatalPositions(
            ascendant: asc,
            bodies: AstroCalculator.positions(of: bodies, at: moment)
        )
    }

    /// Motion-rich batch plus optional zodiac ascendant.
    public static func natalStates(
        for moment: CivilMoment,
        coordinate: GeoCoordinate? = nil,
        bodies: Set<CelestialBody> = [],
        includeAscendant: Bool = false
    ) throws(AstrologyError) -> NatalStates {
        var asc: AscendantResult?
        if includeAscendant {
            guard let coordinate else { throw .missingCoordinateForAscendant }
            asc = try ascendant(for: moment, coordinate: coordinate)
        }
        return NatalStates(
            ascendant: asc,
            bodies: AstroCalculator.states(of: bodies, at: moment)
        )
    }

    /// Full natal chart: positions + houses + angles.
    public static func natalChart(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        bodies: Set<CelestialBody> = Set(CelestialBody.allCases),
        system: HouseSystem = .placidus,
        polarFallback: PolarFallback = .porphyry
    ) throws(AstrologyError) -> NatalChart {
        let houses = try houses(
            for: moment, coordinate: coordinate,
            system: system, polarFallback: polarFallback
        )
        let positions = NatalPositions(
            ascendant: ascendantResult(eclipticLongitude: houses.angles.ascendant),
            bodies: AstroCalculator.positions(of: bodies, at: moment)
        )
        return NatalChart(
            positions: positions, houses: houses,
            moment: moment, coordinate: coordinate
        )
    }
}
