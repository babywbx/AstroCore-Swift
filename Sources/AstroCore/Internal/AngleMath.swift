import Foundation

enum AngleMath {
    // Normalize degrees to [0, 360)
    @inline(__always)
    static func normalized(degrees: Double) -> Double {
        if degrees >= 0.0 && degrees < 360.0 {
            if degrees == 0 { return 0.0 }
            return degrees
        }
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        // Handle -0.0
        if d == 0 { return 0.0 }
        return d
    }

    static let degreesToRadians: Double = .pi / 180.0
    static let radiansToDegrees: Double = 180.0 / .pi

    @inline(__always)
    static func toRadians(_ degrees: Double) -> Double {
        degrees * degreesToRadians
    }

    @inline(__always)
    static func toDegrees(_ radians: Double) -> Double {
        radians * radiansToDegrees
    }

    @inline(__always)
    static func sincos(_ radians: Double) -> (sin: Double, cos: Double) {
        var sinValue = 0.0
        var cosValue = 0.0
        __sincos(radians, &sinValue, &cosValue)
        return (sinValue, cosValue)
    }
}
