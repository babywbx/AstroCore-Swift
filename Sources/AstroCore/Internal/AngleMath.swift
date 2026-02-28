import Foundation

enum AngleMath {
    // Normalize degrees to [0, 360)
    static func normalized(degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360.0)
        if d < 0 { d += 360.0 }
        // Handle -0.0
        if d == 0 { return 0.0 }
        return d
    }

    static let degreesToRadians: Double = .pi / 180.0
    static let radiansToDegrees: Double = 180.0 / .pi

    static func toRadians(_ degrees: Double) -> Double {
        degrees * degreesToRadians
    }

    static func toDegrees(_ radians: Double) -> Double {
        radians * radiansToDegrees
    }
}
