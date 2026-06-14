import AstroCore
import Foundation

/// Independent 36-sector Gauquelin model.
///
/// Numbering follows the clockwise reference convention:
/// sector 1 = Ascendant, sector 10 = MC, sector 19 = Descendant,
/// sector 28 = IC.
enum GauquelinEngine {
    static func compute(
        for moment: CivilMoment,
        coordinate: GeoCoordinate
    ) throws(AstrologyError) -> GauquelinResult {
        let angles = try AnglesEngine.compute(for: moment, coordinate: coordinate)
        let context = HouseEngine.Context(
            moment: moment,
            coordinate: coordinate,
            angles: angles,
            lastDegrees: moment.localApparentSiderealTime(longitude: coordinate.longitude),
            obliquityDegrees: moment.trueObliquity
        )

        let polarCircleLatitude = 90.0 - abs(context.obliquityDegrees)
        guard abs(coordinate.latitude) <= polarCircleLatitude else {
            throw .houseSystemUndefinedAtLatitude(
                system: .placidus,
                latitude: coordinate.latitude
            )
        }

        let wrapped = sectors(context: context).enumerated().map { index, longitude in
            let normalized = AngleMath.normalized(degrees: longitude)
            let details = ZodiacMapper.details(forNormalizedLongitude: normalized)
            return GauquelinSector(
                number: index + 1,
                eclipticLongitude: normalized,
                sign: details.sign,
                degreeInSign: details.degreeInSign
            )
        }

        return GauquelinResult(sectors: wrapped, angles: angles)
    }

    private static func sectors(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let latitude = context.coordinate.latitude
        let obliquity = context.obliquityDegrees
        let ascendant = context.angles.ascendant
        let midheaven = context.angles.midheaven
        let descendant = context.angles.descendant
        let imumCoeli = context.angles.imumCoeli

        var sectors = [Double](repeating: 0.0, count: 36)
        sectors[0] = ascendant
        sectors[9] = midheaven
        sectors[18] = descendant
        sectors[27] = imumCoeli

        let eastUpperArc = AngleMath.normalized(degrees: ascendant - midheaven)
        let westUpperArc = AngleMath.normalized(degrees: descendant - midheaven)

        for sector in 2...9 {
            let fraction = Double(10 - sector) / 9.0
            let seed = AngleMath.normalized(degrees: midheaven + eastUpperArc * fraction)
            sectors[sector - 1] = SemiArcInterpolation.solve(
                fraction: fraction,
                ramc: ramc,
                latitude: latitude,
                obliquity: obliquity,
                initial: seed
            )
            sectors[sector + 17] = AngleMath.normalized(
                degrees: sectors[sector - 1] + 180.0
            )
        }

        for sector in 11...18 {
            let clockwiseSteps = Double(sector - 10)
            let fraction = -clockwiseSteps / 9.0
            let seed = AngleMath.normalized(
                degrees: midheaven + westUpperArc * (clockwiseSteps / 9.0)
            )
            sectors[sector - 1] = SemiArcInterpolation.solve(
                fraction: fraction,
                ramc: ramc,
                latitude: latitude,
                obliquity: obliquity,
                initial: seed
            )
            sectors[sector + 17] = AngleMath.normalized(
                degrees: sectors[sector - 1] + 180.0
            )
        }

        return sectors
    }
}
