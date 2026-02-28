import Foundation

// ΔT = TT - UT1 (seconds)
// Source: Espenak & Meeus (2006), NASA
// Piecewise polynomials for 1800–2100
enum DeltaT {
    private static let coeffs1800To1860 = [
        13.72, -0.332447, 0.0068612, 0.0041116,
        -0.00037436, 0.0000121272, -0.0000001699, 0.000000000875,
    ]
    private static let coeffs1860To1900 = [
        7.62, 0.5737, -0.251754, 0.01680668,
        -0.0004473624, 1.0 / 233174.0,
    ]
    private static let coeffs1900To1920 = [
        -2.79, 1.494119, -0.0598939, 0.0061966, -0.000197,
    ]
    private static let coeffs1920To1941 = [21.20, 0.84493, -0.076100, 0.0020936]
    private static let coeffs1941To1961 = [29.07, 0.407, -1.0 / 233.0, 1.0 / 2547.0]
    private static let coeffs1961To1986 = [45.45, 1.067, -1.0 / 260.0, -1.0 / 718.0]
    private static let coeffs1986To2005 = [
        63.86, 0.3345, -0.060374, 0.0017275,
        0.000651814, 0.00002373599,
    ]
    private static let coeffs2005To2050 = [62.92, 0.32217, 0.005589]

    /// Compute ΔT in seconds for a given decimal year.
    /// Uses Horner's method for polynomial evaluation.
    static func deltaT(decimalYear y: Double) -> Double {
        if y < 1800 || y > 2100 {
            // Extrapolate using the nearest boundary formula
            if y < 1800 { return deltaT(decimalYear: 1800) }
            return deltaT(decimalYear: 2100)
        }

        if y < 1860 {
            // 1800–1860
            let t = y - 1800
            return horner(t, coeffs: coeffs1800To1860)
        }

        if y < 1900 {
            // 1860–1900
            let t = y - 1860
            return horner(t, coeffs: coeffs1860To1900)
        }

        if y < 1920 {
            // 1900–1920
            let t = y - 1900
            return horner(t, coeffs: coeffs1900To1920)
        }

        if y < 1941 {
            // 1920–1941
            let t = y - 1920
            return horner(t, coeffs: coeffs1920To1941)
        }

        if y < 1961 {
            // 1941–1961
            let t = y - 1950
            return horner(t, coeffs: coeffs1941To1961)
        }

        if y < 1986 {
            // 1961–1986
            let t = y - 1975
            return horner(t, coeffs: coeffs1961To1986)
        }

        if y < 2005 {
            // 1986–2005
            let t = y - 2000
            return horner(t, coeffs: coeffs1986To2005)
        }

        if y < 2050 {
            // 2005–2050
            let t = y - 2000
            return horner(t, coeffs: coeffs2005To2050)
        }

        // 2050–2100 (Espenak & Meeus 2006 "2050–2150" formula)
        let u = (y - 1820.0) / 100.0
        return -20 + 32 * u * u - 0.5628 * (2150 - y)
    }

    // Horner's method for polynomial evaluation
    private static func horner(_ x: Double, coeffs: [Double]) -> Double {
        var result = coeffs[coeffs.count - 1]
        for i in stride(from: coeffs.count - 2, through: 0, by: -1) {
            result = result * x + coeffs[i]
        }
        return result
    }
}
