import Foundation

// Mean obliquity of the ecliptic — Laskar (1986)
// 10th-degree polynomial in U = T/100
// Accuracy: 0.01″ over ±10,000 years from J2000.0
enum Obliquity {
    private static let baseObliquityDegrees = 23.0 + 26.0 / 60.0 + 21.448 / 3600.0
    private static let coefficients = [
        0.0, // u^0 offset handled by base
        -4680.93,
        -1.55,
        1999.25,
        -51.38,
        -249.67,
        -39.05,
        7.12,
        27.87,
        5.79,
        2.45,
    ]

    /// Mean obliquity ε₀ in degrees.
    /// T: Julian centuries from J2000.0 in TT.
    static func meanObliquity(julianCenturiesTT t: Double) -> Double {
        let u = t / 100.0
        // Laskar (1986) polynomial — coefficients in arcseconds
        // ε₀ = 23°26′21.448″ + Σ cᵢ × uⁱ
        let arcsec = horner(u, coeffs: coefficients)
        // Base value: 23°26′21.448″ = 23.4392911° = 84381.448″
        return baseObliquityDegrees + arcsec / 3600.0
    }

    // Horner's method
    private static func horner(_ x: Double, coeffs: [Double]) -> Double {
        var result = coeffs[coeffs.count - 1]
        for i in stride(from: coeffs.count - 2, through: 0, by: -1) {
            result = result * x + coeffs[i]
        }
        return result
    }
}
