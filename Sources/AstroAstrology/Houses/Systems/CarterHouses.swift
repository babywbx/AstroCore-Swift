import AstroCore
import Foundation

/// Carter poli-equatorial houses: divide the equator in 30° steps starting
/// from the Ascendant's right ascension, then project those equatorial points
/// back to the ecliptic.
///
/// The system preserves cusp 1 = ASC and cusp 7 = DSC, but cusp 10 generally
/// differs from the true Midheaven because the equatorial partition is anchored
/// to the Ascendant rather than ARMC.
enum CarterHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let epsilon = context.obliquityDegrees
        let cosEpsilon = TrigDeg.cos(epsilon)
        let ascendantRightAscension = rightAscensionOnEcliptic(
            longitude: context.angles.ascendant,
            obliquity: epsilon
        )

        return (0..<12).map { offset in
            let rightAscension = AngleMath.normalized(
                degrees: ascendantRightAscension + 30.0 * Double(offset)
            )
            return AngleMath.normalized(
                degrees: TrigDeg.atan2(
                    TrigDeg.sin(rightAscension),
                    TrigDeg.cos(rightAscension) * cosEpsilon
                )
            )
        }
    }

    private static func rightAscensionOnEcliptic(
        longitude: Double,
        obliquity: Double
    ) -> Double {
        AngleMath.normalized(
            degrees: TrigDeg.atan2(
                TrigDeg.sin(longitude) * TrigDeg.cos(obliquity),
                TrigDeg.cos(longitude)
            )
        )
    }
}
