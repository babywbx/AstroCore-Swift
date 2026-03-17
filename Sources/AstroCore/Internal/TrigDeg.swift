import Foundation

// Degree-based trigonometric functions
enum TrigDeg {
    @inline(__always)
    static func sin(_ degrees: Double) -> Double {
        Foundation.sin(AngleMath.toRadians(degrees))
    }

    @inline(__always)
    static func cos(_ degrees: Double) -> Double {
        Foundation.cos(AngleMath.toRadians(degrees))
    }

    @inline(__always)
    static func tan(_ degrees: Double) -> Double {
        Foundation.tan(AngleMath.toRadians(degrees))
    }

    @inline(__always)
    static func asin(_ value: Double) -> Double {
        AngleMath.toDegrees(Foundation.asin(value))
    }

    @inline(__always)
    static func acos(_ value: Double) -> Double {
        AngleMath.toDegrees(Foundation.acos(value))
    }

    @inline(__always)
    static func atan2(_ y: Double, _ x: Double) -> Double {
        AngleMath.toDegrees(Foundation.atan2(y, x))
    }

    @inline(__always)
    static func sincos(_ degrees: Double) -> (sin: Double, cos: Double) {
        AngleMath.sincos(AngleMath.toRadians(degrees))
    }
}
