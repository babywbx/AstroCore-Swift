import Foundation

/// Pure geometric chart-axis longitudes. No zodiac, no validation.
/// Consumed by the astrology overlay to build houses and angles.
public enum Axis {
    /// Ascendant ecliptic longitude in [0, 360).
    /// λ_ASC = atan2(−cos(LAST), sin(ε)·tan(φ) + cos(ε)·sin(LAST)) + 180°
    @inlinable @inline(__always)
    public static func ascendantLongitude(
        lastDegrees: Double,
        trueObliquityDegrees: Double,
        latitudeDegrees: Double
    ) -> Double {
        let lastRad = AngleMath.toRadians(lastDegrees)
        let oblRad = AngleMath.toRadians(trueObliquityDegrees)
        let latRad = AngleMath.toRadians(latitudeDegrees)
        let lastTrig = AngleMath.sincos(lastRad)
        let oblTrig = AngleMath.sincos(oblRad)
        let y = -lastTrig.cos
        let x = oblTrig.sin * Foundation.tan(latRad) + oblTrig.cos * lastTrig.sin
        let ascRad = Foundation.atan2(y, x)
        return AngleMath.normalized(degrees: AngleMath.toDegrees(ascRad) + 180.0)
    }

    /// Midheaven ecliptic longitude in [0, 360).
    /// λ_MC = atan2(sin(ARMC), cos(ARMC)·cos(ε)); ARMC is LAST in degrees.
    @inlinable @inline(__always)
    public static func midheavenLongitude(
        lastDegrees: Double,
        trueObliquityDegrees: Double
    ) -> Double {
        let lastTrig = AngleMath.sincos(AngleMath.toRadians(lastDegrees))
        let oblCos = Foundation.cos(AngleMath.toRadians(trueObliquityDegrees))
        let mcRad = Foundation.atan2(lastTrig.sin, lastTrig.cos * oblCos)
        return AngleMath.normalized(degrees: AngleMath.toDegrees(mcRad))
    }
}
