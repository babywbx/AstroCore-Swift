import Foundation

/// Degree-based trigonometric functions
public enum TrigDeg {
    @inlinable @inline(__always)
    public static func sin(_ degrees: Double) -> Double {
        Foundation.sin(AngleMath.toRadians(degrees))
    }

    @inlinable @inline(__always)
    public static func cos(_ degrees: Double) -> Double {
        Foundation.cos(AngleMath.toRadians(degrees))
    }

    @inlinable @inline(__always)
    public static func tan(_ degrees: Double) -> Double {
        Foundation.tan(AngleMath.toRadians(degrees))
    }

    @inlinable @inline(__always)
    public static func asin(_ value: Double) -> Double {
        AngleMath.toDegrees(Foundation.asin(value))
    }

    @inlinable @inline(__always)
    public static func acos(_ value: Double) -> Double {
        AngleMath.toDegrees(Foundation.acos(value))
    }

    @inlinable @inline(__always)
    public static func atan2(_ y: Double, _ x: Double) -> Double {
        AngleMath.toDegrees(Foundation.atan2(y, x))
    }

    @inlinable @inline(__always)
    public static func sincos(_ degrees: Double) -> (sin: Double, cos: Double) {
        AngleMath.sincos(AngleMath.toRadians(degrees))
    }
}
