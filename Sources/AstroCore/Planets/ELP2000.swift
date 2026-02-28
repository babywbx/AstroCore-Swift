import Foundation

// Moon position — Meeus Ch.47
// Truncated ELP-2000/82: 60 longitude terms + 60 latitude terms
enum ELP2000 {
    /// Compute geocentric ecliptic position of the Moon.
    /// t: Julian centuries from J2000.0 in TT
    static func compute(julianCenturiesTT t: Double) -> CelestialPosition {
        // Mean longitude of the Moon (L′)
        let lp = AngleMath.normalized(degrees:
            218.3164477 + 481267.88123421 * t - 0.0015786 * t * t
            + t * t * t / 538841.0 - t * t * t * t / 65194000.0
        )

        // Mean elongation of the Moon (D)
        let d = AngleMath.normalized(degrees:
            297.8501921 + 445267.1114034 * t - 0.0018819 * t * t
            + t * t * t / 545868.0 - t * t * t * t / 113065000.0
        )

        // Sun's mean anomaly (M)
        let m = AngleMath.normalized(degrees:
            357.5291092 + 35999.0502909 * t - 0.0001536 * t * t
            + t * t * t / 24490000.0
        )

        // Moon's mean anomaly (M′)
        let mp = AngleMath.normalized(degrees:
            134.9633964 + 477198.8675055 * t + 0.0087414 * t * t
            + t * t * t / 69699.0 - t * t * t * t / 14712000.0
        )

        // Moon's argument of latitude (F)
        let f = AngleMath.normalized(degrees:
            93.2720950 + 483202.0175233 * t - 0.0036539 * t * t
            - t * t * t / 3526000.0 + t * t * t * t / 863310000.0
        )

        // Eccentricity correction factor
        let e = 1.0 - 0.002516 * t - 0.0000074 * t * t
        let e2 = e * e

        // Sum longitude and latitude terms
        var sumL: Double = 0
        var sumB: Double = 0

        for term in longitudeTerms {
            var coeff = Double(term.sinCoeff)
            let arg = Double(term.d) * d + Double(term.m) * m
                + Double(term.mp) * mp + Double(term.f) * f

            // Apply eccentricity correction
            let absM = abs(Int(term.m))
            if absM == 1 { coeff *= e }
            else if absM == 2 { coeff *= e2 }

            sumL += coeff * TrigDeg.sin(arg)
        }

        for term in latitudeTerms {
            var coeff = Double(term.sinCoeff)
            let arg = Double(term.d) * d + Double(term.m) * m
                + Double(term.mp) * mp + Double(term.f) * f

            let absM = abs(Int(term.m))
            if absM == 1 { coeff *= e }
            else if absM == 2 { coeff *= e2 }

            sumB += coeff * TrigDeg.sin(arg)
        }

        // Additional corrections (Meeus p.342)
        let a1 = AngleMath.normalized(degrees: 119.75 + 131.849 * t)
        let a2 = AngleMath.normalized(degrees: 53.09 + 479264.290 * t)
        let a3 = AngleMath.normalized(degrees: 313.45 + 481266.484 * t)

        sumL += 3958.0 * TrigDeg.sin(a1)
            + 1962.0 * TrigDeg.sin(lp - f)
            + 318.0 * TrigDeg.sin(a2)

        sumB += -2235.0 * TrigDeg.sin(lp)
            + 382.0 * TrigDeg.sin(a3)
            + 175.0 * TrigDeg.sin(a1 - f)
            + 175.0 * TrigDeg.sin(a1 + f)
            + 127.0 * TrigDeg.sin(lp - mp)
            - 115.0 * TrigDeg.sin(lp + mp)

        let lonDeg = AngleMath.normalized(degrees: lp + sumL / 1_000_000.0)
        let latDeg = sumB / 1_000_000.0

        let sign = ZodiacMapper.sign(forLongitude: lonDeg)
        let degInSign = ZodiacMapper.degreeInSign(longitude: lonDeg)
        let boundary = ZodiacMapper.isBoundaryCase(longitude: lonDeg)

        return CelestialPosition(
            body: .moon,
            longitude: lonDeg,
            latitude: latDeg,
            sign: sign,
            degreeInSign: degInSign,
            isBoundaryCase: boundary
        )
    }

    // Meeus Table 47.A — 60 longitude terms
    private struct LonTerm {
        let d, m, mp, f: Int8
        let sinCoeff: Int32 // coefficient × 10⁶ (degrees → 0.000001°)
    }

    // Meeus Table 47.B — 60 latitude terms
    private struct LatTerm {
        let d, m, mp, f: Int8
        let sinCoeff: Int32
    }

    // swiftlint:disable comma line_length
    private static let longitudeTerms: [LonTerm] = [
        LonTerm(d:  0, m:  0, mp:  1, f:  0, sinCoeff:  6288774),
        LonTerm(d:  2, m:  0, mp: -1, f:  0, sinCoeff:  1274027),
        LonTerm(d:  2, m:  0, mp:  0, f:  0, sinCoeff:   658314),
        LonTerm(d:  0, m:  0, mp:  2, f:  0, sinCoeff:   213618),
        LonTerm(d:  0, m:  1, mp:  0, f:  0, sinCoeff:  -185116),
        LonTerm(d:  0, m:  0, mp:  0, f:  2, sinCoeff:  -114332),
        LonTerm(d:  2, m:  0, mp: -2, f:  0, sinCoeff:    58793),
        LonTerm(d:  2, m: -1, mp: -1, f:  0, sinCoeff:    57066),
        LonTerm(d:  2, m:  0, mp:  1, f:  0, sinCoeff:    53322),
        LonTerm(d:  2, m: -1, mp:  0, f:  0, sinCoeff:    45758),
        LonTerm(d:  0, m:  1, mp: -1, f:  0, sinCoeff:   -40923),
        LonTerm(d:  1, m:  0, mp:  0, f:  0, sinCoeff:   -34720),
        LonTerm(d:  0, m:  1, mp:  1, f:  0, sinCoeff:   -30383),
        LonTerm(d:  2, m:  0, mp:  0, f: -2, sinCoeff:    15327),
        LonTerm(d:  0, m:  0, mp:  1, f:  2, sinCoeff:   -12528),
        LonTerm(d:  0, m:  0, mp:  1, f: -2, sinCoeff:    10980),
        LonTerm(d:  4, m:  0, mp: -1, f:  0, sinCoeff:    10675),
        LonTerm(d:  0, m:  0, mp:  3, f:  0, sinCoeff:    10034),
        LonTerm(d:  4, m:  0, mp: -2, f:  0, sinCoeff:     8548),
        LonTerm(d:  2, m:  1, mp: -1, f:  0, sinCoeff:    -7888),
        LonTerm(d:  2, m:  1, mp:  0, f:  0, sinCoeff:    -6766),
        LonTerm(d:  1, m:  0, mp: -1, f:  0, sinCoeff:    -5163),
        LonTerm(d:  1, m:  1, mp:  0, f:  0, sinCoeff:     4987),
        LonTerm(d:  2, m: -1, mp:  1, f:  0, sinCoeff:     4036),
        LonTerm(d:  2, m:  0, mp:  2, f:  0, sinCoeff:     3994),
        LonTerm(d:  4, m:  0, mp:  0, f:  0, sinCoeff:     3861),
        LonTerm(d:  2, m:  0, mp: -3, f:  0, sinCoeff:     3665),
        LonTerm(d:  0, m:  1, mp: -2, f:  0, sinCoeff:    -2689),
        LonTerm(d:  2, m:  0, mp: -1, f:  2, sinCoeff:    -2602),
        LonTerm(d:  2, m: -1, mp: -2, f:  0, sinCoeff:     2390),
        LonTerm(d:  1, m:  0, mp:  1, f:  0, sinCoeff:    -2348),
        LonTerm(d:  2, m: -2, mp:  0, f:  0, sinCoeff:     2236),
        LonTerm(d:  0, m:  1, mp:  2, f:  0, sinCoeff:    -2120),
        LonTerm(d:  0, m:  2, mp:  0, f:  0, sinCoeff:    -2069),
        LonTerm(d:  2, m: -2, mp: -1, f:  0, sinCoeff:     2048),
        LonTerm(d:  2, m:  0, mp:  1, f: -2, sinCoeff:    -1773),
        LonTerm(d:  2, m:  0, mp:  0, f:  2, sinCoeff:    -1595),
        LonTerm(d:  4, m: -1, mp: -1, f:  0, sinCoeff:     1215),
        LonTerm(d:  0, m:  0, mp:  2, f:  2, sinCoeff:    -1110),
        LonTerm(d:  3, m:  0, mp: -1, f:  0, sinCoeff:     -892),
        LonTerm(d:  2, m:  1, mp:  1, f:  0, sinCoeff:     -810),
        LonTerm(d:  4, m: -1, mp: -2, f:  0, sinCoeff:      759),
        LonTerm(d:  0, m:  2, mp: -1, f:  0, sinCoeff:     -713),
        LonTerm(d:  2, m:  2, mp: -1, f:  0, sinCoeff:     -700),
        LonTerm(d:  2, m:  1, mp: -2, f:  0, sinCoeff:      691),
        LonTerm(d:  2, m: -1, mp:  0, f: -2, sinCoeff:      596),
        LonTerm(d:  4, m:  0, mp:  1, f:  0, sinCoeff:      549),
        LonTerm(d:  0, m:  0, mp:  4, f:  0, sinCoeff:      537),
        LonTerm(d:  4, m: -1, mp:  0, f:  0, sinCoeff:      520),
        LonTerm(d:  1, m:  0, mp: -2, f:  0, sinCoeff:     -487),
        LonTerm(d:  2, m:  1, mp:  0, f: -2, sinCoeff:     -399),
        LonTerm(d:  0, m:  0, mp:  2, f: -2, sinCoeff:     -381),
        LonTerm(d:  1, m:  1, mp:  1, f:  0, sinCoeff:      351),
        LonTerm(d:  3, m:  0, mp: -2, f:  0, sinCoeff:     -340),
        LonTerm(d:  4, m:  0, mp: -3, f:  0, sinCoeff:      330),
        LonTerm(d:  2, m: -1, mp:  2, f:  0, sinCoeff:      327),
        LonTerm(d:  0, m:  2, mp:  1, f:  0, sinCoeff:     -323),
        LonTerm(d:  1, m:  1, mp: -1, f:  0, sinCoeff:      299),
        LonTerm(d:  2, m:  0, mp:  3, f:  0, sinCoeff:      294),
        LonTerm(d:  2, m:  0, mp: -1, f: -2, sinCoeff:        0),
    ]

    private static let latitudeTerms: [LatTerm] = [
        LatTerm(d:  0, m:  0, mp:  0, f:  1, sinCoeff:  5128122),
        LatTerm(d:  0, m:  0, mp:  1, f:  1, sinCoeff:   280602),
        LatTerm(d:  0, m:  0, mp:  1, f: -1, sinCoeff:   277693),
        LatTerm(d:  2, m:  0, mp:  0, f: -1, sinCoeff:   173237),
        LatTerm(d:  2, m:  0, mp: -1, f:  1, sinCoeff:    55413),
        LatTerm(d:  2, m:  0, mp: -1, f: -1, sinCoeff:    46271),
        LatTerm(d:  2, m:  0, mp:  0, f:  1, sinCoeff:    32573),
        LatTerm(d:  0, m:  0, mp:  2, f:  1, sinCoeff:    17198),
        LatTerm(d:  2, m:  0, mp:  1, f: -1, sinCoeff:     9266),
        LatTerm(d:  0, m:  0, mp:  2, f: -1, sinCoeff:     8822),
        LatTerm(d:  2, m: -1, mp:  0, f: -1, sinCoeff:     8216),
        LatTerm(d:  2, m:  0, mp: -2, f: -1, sinCoeff:     4324),
        LatTerm(d:  2, m:  0, mp:  1, f:  1, sinCoeff:     4200),
        LatTerm(d:  2, m:  1, mp:  0, f: -1, sinCoeff:    -3359),
        LatTerm(d:  2, m: -1, mp: -1, f:  1, sinCoeff:     2463),
        LatTerm(d:  2, m: -1, mp:  0, f:  1, sinCoeff:     2211),
        LatTerm(d:  2, m: -1, mp: -1, f: -1, sinCoeff:     2065),
        LatTerm(d:  0, m:  1, mp: -1, f: -1, sinCoeff:    -1870),
        LatTerm(d:  4, m:  0, mp: -1, f: -1, sinCoeff:     1828),
        LatTerm(d:  0, m:  1, mp:  0, f:  1, sinCoeff:    -1794),
        LatTerm(d:  0, m:  0, mp:  0, f:  3, sinCoeff:    -1749),
        LatTerm(d:  0, m:  1, mp: -1, f:  1, sinCoeff:    -1565),
        LatTerm(d:  1, m:  0, mp:  0, f:  1, sinCoeff:    -1491),
        LatTerm(d:  0, m:  1, mp:  1, f:  1, sinCoeff:    -1475),
        LatTerm(d:  0, m:  1, mp:  1, f: -1, sinCoeff:    -1410),
        LatTerm(d:  0, m:  1, mp:  0, f: -1, sinCoeff:    -1344),
        LatTerm(d:  1, m:  0, mp:  0, f: -1, sinCoeff:    -1335),
        LatTerm(d:  0, m:  0, mp:  3, f:  1, sinCoeff:     1107),
        LatTerm(d:  4, m:  0, mp:  0, f: -1, sinCoeff:     1021),
        LatTerm(d:  4, m:  0, mp: -1, f:  1, sinCoeff:      833),
        LatTerm(d:  0, m:  0, mp:  1, f: -3, sinCoeff:      777),
        LatTerm(d:  4, m:  0, mp: -2, f:  1, sinCoeff:      671),
        LatTerm(d:  2, m:  0, mp:  0, f: -3, sinCoeff:      607),
        LatTerm(d:  2, m:  0, mp:  2, f: -1, sinCoeff:      596),
        LatTerm(d:  2, m: -1, mp:  1, f: -1, sinCoeff:      491),
        LatTerm(d:  2, m:  0, mp: -2, f:  1, sinCoeff:     -451),
        LatTerm(d:  0, m:  0, mp:  3, f: -1, sinCoeff:      439),
        LatTerm(d:  2, m:  0, mp:  2, f:  1, sinCoeff:      422),
        LatTerm(d:  2, m:  0, mp: -3, f: -1, sinCoeff:      421),
        LatTerm(d:  2, m:  1, mp: -1, f:  1, sinCoeff:     -366),
        LatTerm(d:  2, m:  1, mp:  0, f:  1, sinCoeff:     -351),
        LatTerm(d:  4, m:  0, mp:  0, f:  1, sinCoeff:      331),
        LatTerm(d:  2, m: -1, mp:  1, f:  1, sinCoeff:      315),
        LatTerm(d:  2, m: -2, mp:  0, f: -1, sinCoeff:      302),
        LatTerm(d:  0, m:  0, mp:  1, f:  3, sinCoeff:     -283),
        LatTerm(d:  2, m:  1, mp:  1, f: -1, sinCoeff:     -229),
        LatTerm(d:  1, m:  1, mp:  0, f: -1, sinCoeff:      223),
        LatTerm(d:  1, m:  1, mp:  0, f:  1, sinCoeff:      223),
        LatTerm(d:  0, m:  1, mp: -2, f: -1, sinCoeff:     -220),
        LatTerm(d:  2, m:  1, mp: -1, f: -1, sinCoeff:     -220),
        LatTerm(d:  1, m:  0, mp:  1, f:  1, sinCoeff:     -185),
        LatTerm(d:  2, m: -1, mp: -2, f: -1, sinCoeff:      181),
        LatTerm(d:  0, m:  1, mp:  2, f:  1, sinCoeff:     -177),
        LatTerm(d:  4, m:  0, mp: -2, f: -1, sinCoeff:      176),
        LatTerm(d:  4, m: -1, mp: -1, f: -1, sinCoeff:      166),
        LatTerm(d:  1, m:  0, mp:  1, f: -1, sinCoeff:     -164),
        LatTerm(d:  4, m:  0, mp:  1, f: -1, sinCoeff:      132),
        LatTerm(d:  1, m:  0, mp: -1, f: -1, sinCoeff:     -119),
        LatTerm(d:  4, m: -1, mp:  0, f: -1, sinCoeff:      115),
        LatTerm(d:  2, m: -2, mp:  0, f:  1, sinCoeff:      107),
    ]
    // swiftlint:enable comma line_length
}
