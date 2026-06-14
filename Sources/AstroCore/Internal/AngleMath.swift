import Foundation

/// Angle utilities. `@inlinable` so overlay modules keep inlining these across the module boundary.
public enum AngleMath {
    /// Normalize degrees to [0, 360)
    @inlinable @inline(__always)
    public static func normalized(degrees: Double) -> Double {
        if degrees > 0.0 && degrees < 360.0 { return degrees }
        if degrees == 0.0 { return 0.0 } // canonicalize -0.0
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        // Handle -0.0
        if d == 0 { return 0.0 }
        return d
    }

    public static let degreesToRadians: Double = .pi / 180.0
    public static let radiansToDegrees: Double = 180.0 / .pi

    @inlinable @inline(__always)
    public static func toRadians(_ degrees: Double) -> Double {
        degrees * degreesToRadians
    }

    @inlinable @inline(__always)
    public static func toDegrees(_ radians: Double) -> Double {
        radians * radiansToDegrees
    }

    @inlinable @inline(__always)
    public static func sincos(_ radians: Double) -> (sin: Double, cos: Double) {
        var sinValue = 0.0
        var cosValue = 0.0
        __sincos(radians, &sinValue, &cosValue)
        return (sinValue, cosValue)
    }
}
