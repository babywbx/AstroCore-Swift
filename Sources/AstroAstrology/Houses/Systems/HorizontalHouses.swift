import AstroCore
import Foundation

/// Horizontal (azimuthal) houses: divide the horizon into twelve directions
/// starting from the eastern point, construct the vertical great circle through
/// each direction and the zenith, then intersect that great circle with the
/// ecliptic.
///
/// Cardinal anchors:
/// - cusp 1 = antivertex (east point)
/// - cusp 4 = IC
/// - cusp 7 = vertex (west point)
/// - cusp 10 = MC
enum HorizontalHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let latitude = context.coordinate.latitude
        let obliquity = context.obliquityDegrees
        let porphyry = PorphyryHouses.porphyryCusps(angles: context.angles)
        let zenith = EquatorialVector(rightAscension: ramc, declination: latitude)
        let antivertex = context.angles.vertex.map {
            AngleMath.normalized(degrees: $0 + 180.0)
        }

        return (1...12).map { number in
            let azimuthStep = 30.0 * Double(number - 1)
            let azimuth = latitude >= 0.0
                ? AngleMath.normalized(degrees: 90.0 - azimuthStep)
                : AngleMath.normalized(degrees: 90.0 + azimuthStep)
            let horizonPoint = EquatorialVector.horizonPoint(
                azimuth: azimuth,
                lastDegrees: ramc,
                latitudeDegrees: latitude
            )
            let planeNormal = zenith.cross(horizonPoint)
            let candidate = planeNormal.eclipticIntersectionLongitude(
                obliquityDegrees: obliquity
            )
            let opposite = AngleMath.normalized(degrees: candidate + 180.0)
            let target = targetLongitude(
                for: number,
                context: context,
                porphyry: porphyry,
                antivertex: antivertex
            )
            return closerLongitude(
                candidate,
                opposite,
                target: target
            )
        }
    }

    private static func targetLongitude(
        for number: Int,
        context: HouseEngine.Context,
        porphyry: [Double],
        antivertex: Double?
    ) -> Double {
        switch number {
        case 1:
            antivertex ?? porphyry[0]
        case 4:
            context.angles.imumCoeli
        case 7:
            context.angles.vertex ?? porphyry[6]
        case 10:
            context.angles.midheaven
        default:
            porphyry[number - 1]
        }
    }

    private static func closerLongitude(
        _ lhs: Double,
        _ rhs: Double,
        target: Double
    ) -> Double {
        let lhsDelta = circularDistance(lhs, target)
        let rhsDelta = circularDistance(rhs, target)
        return lhsDelta <= rhsDelta ? lhs : rhs
    }

    private static func circularDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let delta = AngleMath.normalized(degrees: lhs - rhs)
        return min(delta, 360.0 - delta)
    }
}
