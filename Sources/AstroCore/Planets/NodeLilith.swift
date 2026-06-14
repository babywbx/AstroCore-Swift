import Foundation

/// Lunar nodes and Lilith variants; computed points have no distance.
/// Mean node and mean apogee are polynomials in T (Julian centuries TT); the true node is the
/// instantaneous (osculating) ascending node of the Moon's orbit. Nutation is added by the caller.
/// trueLilith projects the mean apogee onto the inclined mean lunar orbit.
enum NodeLilith {
    private static let meanNodeCoeffs: [Double] = [
        -3834.9554449555, -1934.1363156137, 0.0020714696, 0.0000019058, -0.0000000209
    ]
    private static let meanApogeeCoeffs: [Double] = [
        8183.3526721704, 4069.0135068402, -0.0078241867, 0.0011097315, -0.0002642278
    ]

    /// Mean inclination of the lunar orbit to the ecliptic (degrees).
    private static let meanInclinationDeg = 5.145396

    static func position(
        _ body: CelestialBody, julianCenturiesTT t: Double
    ) -> RawCelestialPosition {
        if body == .trueLilith {
            return projectedApogee(julianCenturiesTT: t)
        }
        let longitude: Double = switch body {
        case .meanNode: polynomial(meanNodeCoeffs, t)
        case .lilith: polynomial(meanApogeeCoeffs, t)
        case .trueNode: trueNode(julianCenturiesTT: t)
        default: 0.0
        }
        return RawCelestialPosition(
            body: body,
            longitude: AngleMath.normalized(degrees: longitude),
            latitude: 0.0
        )
    }

    /// Mean apogee projected onto the inclined mean orbit and ecliptic.
    private static func projectedApogee(julianCenturiesTT t: Double) -> RawCelestialPosition {
        let node = polynomial(meanNodeCoeffs, t)
        let apogee = polynomial(meanApogeeCoeffs, t)
        let uTrig = AngleMath.sincos(AngleMath.toRadians(apogee - node))
        let iTrig = AngleMath.sincos(AngleMath.toRadians(meanInclinationDeg))
        let latitude = AngleMath.toDegrees(Foundation.asin(iTrig.sin * uTrig.sin))
        let longitude = node + AngleMath.toDegrees(
            Foundation.atan2(iTrig.cos * uTrig.sin, uTrig.cos)
        )
        return RawCelestialPosition(
            body: .trueLilith,
            longitude: AngleMath.normalized(degrees: longitude),
            latitude: latitude
        )
    }

    @inline(__always)
    private static func polynomial(_ coeffs: [Double], _ t: Double) -> Double {
        var result = 0.0
        var power = 1.0
        for coefficient in coeffs {
            result += coefficient * power
            power *= t
        }
        return result
    }

    /// Osculating ascending node from the Moon's instantaneous orbit plane (r x v direction).
    private static func trueNode(julianCenturiesTT t: Double) -> Double {
        let dt = 0.05 / 36525.0
        let before = moonDirection(t - dt)
        let after = moonDirection(t + dt)
        let here = moonDirection(t)
        let vx = after.x - before.x
        let vy = after.y - before.y
        let vz = after.z - before.z
        let hx = here.y * vz - here.z * vy
        let hy = here.z * vx - here.x * vz
        let hz = here.x * vy - here.y * vx
        var node = AngleMath.toDegrees(Foundation.atan2(hx, -hy))
        if hz < 0.0 { node += 180.0 }
        return node
    }

    @inline(__always)
    private static func moonDirection(_ t: Double) -> (x: Double, y: Double, z: Double) {
        let moon = ELP2000.compute(julianCenturiesTT: t)
        let latTrig = AngleMath.sincos(AngleMath.toRadians(moon.latitude))
        let lonTrig = AngleMath.sincos(AngleMath.toRadians(moon.longitude))
        return (
            x: latTrig.cos * lonTrig.cos,
            y: latTrig.cos * lonTrig.sin,
            z: latTrig.sin
        )
    }
}
