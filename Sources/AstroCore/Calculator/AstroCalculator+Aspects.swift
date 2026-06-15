import Foundation

extension AstroCalculator {
    /// Signed deviation = shortest-arc separation − aspect angle (deg), range [-180, 180]; |value| is the orb gap.
    public static func aspectSeparation(
        longitudeA: Double,
        longitudeB: Double,
        aspectAngleDegrees: Double
    ) -> Double {
        let delta = wrappedDelta(longitudeB - longitudeA)
        return abs(delta) - aspectAngleDegrees
    }

    /// Continuous closing rate (deg/day) of the (A,B) pair toward the aspect.
    /// SIGN CONTRACT: closingRate > 0 ⟺ applying (gap shrinking);
    ///                closingRate < 0 ⟺ separating; == 0 ⟺ exact / stationary.
    /// The "+ / −" here is unrelated to isRetrograde's "negative = retrograde".
    public static func aspectClosingRate(
        speedA: Double,
        speedB: Double,
        longitudeA: Double,
        longitudeB: Double,
        aspectAngleDegrees: Double
    ) -> Double {
        let delta = wrappedDelta(longitudeB - longitudeA)
        let separation = abs(delta)
        let relSpeed = speedB - speedA
        return -signum(separation - aspectAngleDegrees) * signum(delta) * relSpeed
    }

    /// Fold a raw degree difference into (-180, 180] using the canonical normalizer.
    @inline(__always)
    static func wrappedDelta(_ raw: Double) -> Double {
        let n = AngleMath.normalized(degrees: raw)
        return n > 180.0 ? n - 360.0 : n
    }

    @inline(__always)
    static func signum(_ value: Double) -> Double {
        value > 0.0 ? 1.0 : (value < 0.0 ? -1.0 : 0.0)
    }
}
