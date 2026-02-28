import Foundation

// Nutation — IAU 1980 theory, full 63 terms
// Meeus Table 22.A
// Five fundamental arguments: D, M, M′, F, Ω
enum Nutation {
    struct Result: Sendable {
        let longitude: Double // Δψ in arcseconds
        let obliquity: Double // Δε in arcseconds
    }

    /// Compute nutation in longitude (Δψ) and obliquity (Δε).
    /// T: Julian centuries from J2000.0 in TT.
    static func compute(julianCenturiesTT t: Double) -> Result {
        // Fundamental arguments in degrees (Meeus Ch.22)

        // D: Mean elongation of the Moon from the Sun
        let d = AngleMath.normalized(degrees:
            297.85036 + 445267.111480 * t - 0.0019142 * t * t
            + t * t * t / 189474.0
        )

        // M: Mean anomaly of the Sun (Earth)
        let m = AngleMath.normalized(degrees:
            357.52772 + 35999.050340 * t - 0.0001603 * t * t
            - t * t * t / 300000.0
        )

        // M′: Mean anomaly of the Moon
        let mp = AngleMath.normalized(degrees:
            134.96298 + 477198.867398 * t + 0.0086972 * t * t
            + t * t * t / 56250.0
        )

        // F: Moon's argument of latitude
        let f = AngleMath.normalized(degrees:
            93.27191 + 483202.017538 * t - 0.0036825 * t * t
            + t * t * t / 327270.0
        )

        // Ω: Longitude of ascending node of Moon's orbit
        let omega = AngleMath.normalized(degrees:
            125.04452 - 1934.136261 * t + 0.0020708 * t * t
            + t * t * t / 450000.0
        )

        var deltaPsi: Double = 0
        var deltaEps: Double = 0

        for term in terms {
            let arg = Double(term.d) * d + Double(term.m) * m
                + Double(term.mp) * mp + Double(term.f) * f
                + Double(term.omega) * omega

            let argRad = AngleMath.toRadians(arg)
            let sinArg = Foundation.sin(argRad)
            let cosArg = Foundation.cos(argRad)

            // s/c in 0.0001″; sp/cp stored as tenths of 0.0001″/cy
            deltaPsi += (Double(term.s) + 0.1 * Double(term.sp) * t) * sinArg
            deltaEps += (Double(term.c) + 0.1 * Double(term.cp) * t) * cosArg
        }

        // Convert from 0.0001″ to arcseconds
        return Result(
            longitude: deltaPsi / 10000.0,
            obliquity: deltaEps / 10000.0
        )
    }

    // IAU 1980 nutation coefficients — full 63 terms
    // Columns: D, M, M′, F, Ω, S(0.0001″), S′(0.0001″/cy), C(0.0001″), C′(0.0001″/cy)
    private struct Term {
        let d, m, mp, f, omega: Int8
        let s: Int32   // Δψ sine coefficient (0.0001″)
        let sp: Int16  // Δψ sine T coefficient (0.0001″/cy)
        let c: Int32   // Δε cosine coefficient (0.0001″)
        let cp: Int16  // Δε cosine T coefficient (0.0001″/cy)
    }

    // swiftlint:disable comma line_length
    private static let terms: [Term] = [
        // Meeus Table 22.A — all 63 terms
        Term(d:  0, m:  0, mp:  0, f:  0, omega:  1, s: -171996, sp: -1742, c:  92025, cp:  89),
        Term(d: -2, m:  0, mp:  0, f:  2, omega:  2, s:  -13187, sp:   -16, c:   5736, cp: -31),
        Term(d:  0, m:  0, mp:  0, f:  2, omega:  2, s:   -2274, sp:    -2, c:    977, cp:  -5),
        Term(d:  0, m:  0, mp:  0, f:  0, omega:  2, s:    2062, sp:     2, c:   -895, cp:   5),
        Term(d:  0, m:  1, mp:  0, f:  0, omega:  0, s:    1426, sp:   -34, c:     54, cp:  -1),
        Term(d:  0, m:  0, mp:  1, f:  0, omega:  0, s:     712, sp:     1, c:     -7, cp:   0),
        Term(d: -2, m:  1, mp:  0, f:  2, omega:  2, s:    -517, sp:    12, c:    224, cp:  -6),
        Term(d:  0, m:  0, mp:  0, f:  2, omega:  1, s:    -386, sp:    -4, c:    200, cp:   0),
        Term(d:  0, m:  0, mp:  1, f:  2, omega:  2, s:    -301, sp:     0, c:    129, cp:  -1),
        Term(d: -2, m: -1, mp:  0, f:  2, omega:  2, s:     217, sp:    -5, c:    -95, cp:   3),
        // 11-20
        Term(d: -2, m:  0, mp:  1, f:  0, omega:  0, s:    -158, sp:     0, c:      0, cp:   0),
        Term(d: -2, m:  0, mp:  0, f:  2, omega:  1, s:     129, sp:     1, c:    -70, cp:   0),
        Term(d:  0, m:  0, mp: -1, f:  2, omega:  2, s:     123, sp:     0, c:    -53, cp:   0),
        Term(d:  2, m:  0, mp:  0, f:  0, omega:  0, s:      63, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  0, mp:  1, f:  0, omega:  1, s:      63, sp:     1, c:    -33, cp:   0),
        Term(d:  2, m:  0, mp: -1, f:  2, omega:  2, s:     -59, sp:     0, c:     26, cp:   0),
        Term(d:  0, m:  0, mp: -1, f:  0, omega:  1, s:     -58, sp:    -1, c:     32, cp:   0),
        Term(d:  0, m:  0, mp:  1, f:  2, omega:  1, s:     -51, sp:     0, c:     27, cp:   0),
        Term(d: -2, m:  0, mp:  2, f:  0, omega:  0, s:      48, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  0, mp: -2, f:  2, omega:  1, s:      46, sp:     0, c:    -24, cp:   0),
        // 21-30
        Term(d:  2, m:  0, mp:  0, f:  2, omega:  2, s:     -38, sp:     0, c:     16, cp:   0),
        Term(d:  0, m:  0, mp:  2, f:  2, omega:  2, s:     -31, sp:     0, c:     13, cp:   0),
        Term(d:  0, m:  0, mp:  2, f:  0, omega:  0, s:      29, sp:     0, c:      0, cp:   0),
        Term(d: -2, m:  0, mp:  1, f:  2, omega:  2, s:      29, sp:     0, c:    -12, cp:   0),
        Term(d:  0, m:  0, mp:  0, f:  2, omega:  0, s:      26, sp:     0, c:      0, cp:   0),
        Term(d: -2, m:  0, mp:  0, f:  2, omega:  0, s:     -22, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  0, mp: -1, f:  2, omega:  1, s:      21, sp:     0, c:    -10, cp:   0),
        Term(d:  0, m:  2, mp:  0, f:  0, omega:  0, s:      17, sp:    -1, c:      0, cp:   0),
        Term(d:  2, m:  0, mp: -1, f:  0, omega:  1, s:      16, sp:     0, c:     -8, cp:   0),
        Term(d: -2, m:  2, mp:  0, f:  2, omega:  2, s:     -16, sp:     1, c:      7, cp:   0),
        // 31-40
        Term(d:  0, m:  1, mp:  0, f:  0, omega:  1, s:     -15, sp:     0, c:      9, cp:   0),
        Term(d: -2, m:  0, mp:  1, f:  0, omega:  1, s:     -13, sp:     0, c:      7, cp:   0),
        Term(d:  0, m: -1, mp:  0, f:  0, omega:  1, s:     -12, sp:     0, c:      6, cp:   0),
        Term(d:  0, m:  0, mp:  2, f: -2, omega:  0, s:      11, sp:     0, c:      0, cp:   0),
        Term(d:  2, m:  0, mp: -1, f:  2, omega:  1, s:     -10, sp:     0, c:      5, cp:   0),
        Term(d:  2, m:  0, mp:  1, f:  2, omega:  2, s:      -8, sp:     0, c:      3, cp:   0),
        Term(d:  0, m:  1, mp:  0, f:  2, omega:  2, s:       7, sp:     0, c:     -3, cp:   0),
        Term(d: -2, m:  1, mp:  1, f:  0, omega:  0, s:      -7, sp:     0, c:      0, cp:   0),
        Term(d:  0, m: -1, mp:  0, f:  2, omega:  2, s:      -7, sp:     0, c:      3, cp:   0),
        Term(d:  2, m:  0, mp:  0, f:  2, omega:  1, s:      -7, sp:     0, c:      3, cp:   0),
        // 41-50
        Term(d:  2, m:  0, mp:  1, f:  0, omega:  0, s:      -6, sp:     0, c:      0, cp:   0),
        Term(d: -2, m:  0, mp:  2, f:  2, omega:  2, s:      -6, sp:     0, c:      3, cp:   0),
        Term(d: -2, m:  0, mp:  1, f:  2, omega:  1, s:       6, sp:     0, c:     -3, cp:   0),
        Term(d:  2, m:  0, mp: -2, f:  0, omega:  1, s:      -6, sp:     0, c:      3, cp:   0),
        Term(d:  2, m:  0, mp:  0, f:  0, omega:  1, s:      -5, sp:     0, c:      3, cp:   0),
        Term(d:  0, m: -1, mp:  1, f:  0, omega:  0, s:      -5, sp:     0, c:      0, cp:   0),
        Term(d: -2, m: -1, mp:  0, f:  2, omega:  1, s:      -5, sp:     0, c:      3, cp:   0),
        Term(d: -2, m:  0, mp:  0, f:  0, omega:  1, s:       4, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  0, mp:  2, f:  2, omega:  1, s:       4, sp:     0, c:     -2, cp:   0),
        Term(d: -2, m:  0, mp:  2, f:  0, omega:  1, s:       4, sp:     0, c:     -2, cp:   0),
        // 51-60
        Term(d: -2, m:  1, mp:  0, f:  2, omega:  1, s:      -4, sp:     0, c:      2, cp:   0),
        Term(d:  0, m:  0, mp:  1, f: -2, omega:  0, s:       4, sp:     0, c:      0, cp:   0),
        Term(d: -1, m:  0, mp:  1, f:  0, omega:  0, s:      -4, sp:     0, c:      0, cp:   0),
        Term(d: -2, m:  1, mp:  0, f:  0, omega:  0, s:      -3, sp:     0, c:      0, cp:   0),
        Term(d:  1, m:  0, mp:  0, f:  0, omega:  0, s:       3, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  0, mp:  1, f:  2, omega:  0, s:      -3, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  0, mp: -2, f:  2, omega:  2, s:      -3, sp:     0, c:      1, cp:   0),
        Term(d: -1, m: -1, mp:  1, f:  0, omega:  0, s:      -3, sp:     0, c:      0, cp:   0),
        Term(d:  0, m:  1, mp:  1, f:  0, omega:  0, s:      -3, sp:     0, c:      0, cp:   0),
        Term(d:  0, m: -1, mp:  1, f:  2, omega:  2, s:      -3, sp:     0, c:      1, cp:   0),
        // 61-63
        Term(d:  2, m: -1, mp: -1, f:  2, omega:  2, s:      -3, sp:     0, c:      1, cp:   0),
        Term(d:  0, m:  0, mp:  3, f:  2, omega:  2, s:      -3, sp:     0, c:      1, cp:   0),
        Term(d:  2, m: -1, mp:  0, f:  2, omega:  2, s:      -3, sp:     0, c:      1, cp:   0),
    ]
    // swiftlint:enable comma line_length
}
