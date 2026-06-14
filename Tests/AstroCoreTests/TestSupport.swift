@testable import AstroCore
import Testing

enum AstroCoreTestSupport {
    static func circularDifference(_ lhs: Double, _ rhs: Double) -> Double {
        let diff = abs(AngleMath.normalized(degrees: lhs - rhs))
        return min(diff, 360.0 - diff)
    }

    static func expectCircularlyEqual(
        _ lhs: Double,
        _ rhs: Double,
        tolerance: Double,
        _ message: String = ""
    ) {
        let diff = circularDifference(lhs, rhs)
        if message.isEmpty {
            #expect(diff < tolerance)
        } else {
            #expect(diff < tolerance, "\(message) (Δ=\(diff)°)")
        }
    }
}
