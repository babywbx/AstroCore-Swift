import Foundation

/// Empirical Moon residual corrections (longitude + latitude) for the supported civil range.
///
/// Fitted in the lunar fundamental-argument basis (D, M, M′, F, Ω) against the apparent
/// local validation baseline. The base ELP2000 series plus geocentric light-time remain the primary model;
/// these terms remove the residual truncation hotspots to sub-arcsecond.
enum MoonResiduals {
    struct Term {
        let d, m, mp, f, o: Int8
        let amplitude: Double // arcseconds
        let phase: Double // radians
    }

    @inline(__always)
    static func longitudeArcsec(
        d: Double, m: Double, mp: Double, f: Double, omega: Double
    ) -> Double {
        evaluate(longitudeTerms, d: d, m: m, mp: mp, f: f, omega: omega)
    }

    @inline(__always)
    static func latitudeArcsec(
        d: Double, m: Double, mp: Double, f: Double, omega: Double
    ) -> Double {
        evaluate(latitudeTerms, d: d, m: m, mp: mp, f: f, omega: omega)
    }

    @inline(__always)
    private static func evaluate(
        _ terms: [Term], d: Double, m: Double, mp: Double, f: Double, omega: Double
    ) -> Double {
        let deg2rad = Double.pi / 180.0
        var total = 0.0
        for term in terms {
            let arg = (Double(term.d) * d + Double(term.m) * m
                + Double(term.mp) * mp + Double(term.f) * f
                + Double(term.o) * omega) * deg2rad
            total += term.amplitude * Foundation.sin(arg + term.phase)
        }
        return total
    }

    // swiftlint:disable comma line_length
    private static let longitudeTerms: [Term] = [
        Term(d: 1, m: 1, mp: 0, f: -1, o: -1, amplitude: 30.8817095335, phase: 1.8242607569),
        Term(d: 2, m: 0, mp: 1, f: 2, o: 0, amplitude: 0.9900205133, phase: 0.0005085097),
        Term(d: 2, m: 0, mp: -4, f: 0, o: 0, amplitude: 0.9484767452, phase: 3.1410871035),
        Term(d: 2, m: -2, mp: 1, f: 0, o: 0, amplitude: 0.7541284279, phase: -3.1406958021),
        Term(d: 0, m: 1, mp: -3, f: 0, o: 0, amplitude: 0.6699168760, phase: -0.0005379508),
        Term(d: 4, m: 1, mp: -1, f: 0, o: 0, amplitude: 0.6363868604, phase: 0.0003849553),
        Term(d: 1, m: 0, mp: 0, f: -2, o: 0, amplitude: 0.5839549622, phase: -0.0026036848),
        Term(d: 1, m: 0, mp: 2, f: 0, o: 0, amplitude: 0.5837284171, phase: 0.0011522316),
        Term(d: 4, m: -2, mp: -2, f: 2, o: 2, amplitude: 0.5711340566, phase: -0.4214160742),
        Term(d: 1, m: -1, mp: 0, f: 0, o: 0, amplitude: 0.5617470350, phase: -0.0083947053),
        Term(d: 2, m: 0, mp: -2, f: -2, o: 0, amplitude: 0.5610273441, phase: 0.0002867992),
        Term(d: 0, m: 1, mp: 3, f: 0, o: 0, amplitude: 0.5465204870, phase: 0.0005144048),
        Term(d: 2, m: 0, mp: -2, f: 2, o: 0, amplitude: 0.5352474083, phase: 0.0022477368),
        Term(d: 1, m: 1, mp: -1, f: -1, o: -2, amplitude: 0.5081920631, phase: -1.2423111635),
        Term(d: 2, m: 2, mp: -1, f: -1, o: 1, amplitude: 0.5036228644, phase: 2.0900778153),
        Term(d: 1, m: 1, mp: -1, f: -1, o: 0, amplitude: 0.4986857463, phase: 1.6516662697),
        Term(d: 2, m: -1, mp: -3, f: 0, o: 0, amplitude: 0.4790061491, phase: -3.1406018098),
        Term(d: 2, m: 0, mp: 2, f: -2, o: 0, amplitude: 0.4550310976, phase: 0.0010796062),
        Term(d: 2, m: 2, mp: -2, f: -1, o: 1, amplitude: 0.4539124387, phase: -2.7074274682),
        Term(d: 2, m: 2, mp: 0, f: -1, o: 1, amplitude: 0.4425214319, phase: -2.6472079970),
        Term(d: 2, m: -1, mp: -1, f: 2, o: 0, amplitude: 0.4263852111, phase: 0.0003064575),
        Term(d: 0, m: 0, mp: 0, f: 4, o: 0, amplitude: 0.4203928318, phase: -3.1415580440),
        Term(d: 0, m: 1, mp: 0, f: 2, o: 0, amplitude: 0.4139990051, phase: 3.1415657505),
        Term(d: 3, m: 0, mp: 0, f: 0, o: 0, amplitude: 0.4040174741, phase: -3.1396307356)
    ]

    private static let latitudeTerms: [Term] = [
        Term(d: 3, m: 0, mp: 0, f: -1, o: 0, amplitude: 0.3517610326, phase: -0.0010947452),
        Term(d: 4, m: -1, mp: -1, f: 1, o: 0, amplitude: 0.3392345242, phase: -3.1410837355),
        Term(d: 2, m: 0, mp: -1, f: -3, o: 0, amplitude: 0.3286539826, phase: 3.1413957104),
        Term(d: 1, m: 1, mp: 0, f: -2, o: 0, amplitude: 0.3226998947, phase: 1.7624652458),
        Term(d: 2, m: -2, mp: -1, f: 1, o: 0, amplitude: 0.3156551041, phase: -3.1412869761),
        Term(d: 0, m: 1, mp: 2, f: -1, o: 0, amplitude: 0.3126420134, phase: 0.0006935441),
        Term(d: 2, m: 0, mp: 0, f: -1, o: -1, amplitude: 0.3067219153, phase: 0.1473935893),
        Term(d: 3, m: 0, mp: -1, f: -1, o: 0, amplitude: 0.3053143061, phase: -0.0026910634),
        Term(d: 0, m: 1, mp: -2, f: 1, o: 0, amplitude: 0.3015564334, phase: 0.0001592274),
        Term(d: 2, m: 0, mp: 1, f: -3, o: 0, amplitude: 0.2912590712, phase: 0.0006030673),
        Term(d: 2, m: -2, mp: -1, f: -1, o: 0, amplitude: 0.2692732414, phase: -3.1415521381),
        Term(d: 0, m: 0, mp: 4, f: 1, o: 0, amplitude: 0.2632683799, phase: -3.1410665751),
        Term(d: 2, m: 0, mp: -3, f: 1, o: 0, amplitude: 0.2542902321, phase: 3.1411997146),
        Term(d: 2, m: 0, mp: -1, f: 3, o: 0, amplitude: 0.2448096605, phase: 0.0003558339),
        Term(d: 2, m: 1, mp: 1, f: 1, o: 0, amplitude: 0.2369777828, phase: 0.0000525058),
        Term(d: 4, m: -1, mp: -2, f: 1, o: 0, amplitude: 0.2140657709, phase: -3.1412902978),
        Term(d: 4, m: 0, mp: 1, f: 1, o: 0, amplitude: 0.2125799292, phase: -3.1409426969),
        Term(d: 1, m: 1, mp: 0, f: 0, o: 1, amplitude: 0.2103363932, phase: 1.5245826359),
        Term(d: 3, m: 0, mp: -1, f: 1, o: 0, amplitude: 0.2059666181, phase: -0.0003876376),
        Term(d: 4, m: 1, mp: -1, f: -1, o: 0, amplitude: 0.1718516484, phase: -0.0019435262),
        Term(d: 4, m: -1, mp: 0, f: 1, o: 0, amplitude: 0.1580342315, phase: -3.1411630426),
        Term(d: 2, m: 0, mp: 3, f: -1, o: 0, amplitude: 0.1464082350, phase: -3.1407726775),
        Term(d: 2, m: 0, mp: 0, f: 3, o: 0, amplitude: 0.1444962523, phase: 0.0005126288),
        Term(d: 1, m: 0, mp: -1, f: 1, o: 0, amplitude: 0.1391919064, phase: -3.1389196590),
        Term(d: 2, m: 0, mp: 3, f: 1, o: 0, amplitude: 0.1379294925, phase: -3.1408663169),
        Term(d: 1, m: 1, mp: 0, f: -2, o: -2, amplitude: 0.1345965319, phase: 2.9206768911),
        Term(d: 2, m: 0, mp: -4, f: -1, o: 0, amplitude: 0.1338660119, phase: 3.1407069550),
        Term(d: 0, m: 0, mp: 2, f: -3, o: 0, amplitude: 0.1310195564, phase: 0.0074429799),
        Term(d: 2, m: -1, mp: 2, f: -1, o: 0, amplitude: 0.1291192149, phase: 3.1404931196),
        Term(d: 2, m: -1, mp: 2, f: 1, o: 0, amplitude: 0.1239559796, phase: -3.1412648890),
        Term(d: 0, m: 0, mp: 2, f: 3, o: 0, amplitude: 0.1178478624, phase: 0.0005904841),
        Term(d: 0, m: 2, mp: -1, f: -1, o: 0, amplitude: 0.1154216898, phase: 0.0528662570),
        Term(d: 2, m: 2, mp: -1, f: 1, o: 0, amplitude: 0.1142749590, phase: -0.0020610183),
        Term(d: 4, m: 1, mp: 0, f: -1, o: 0, amplitude: 0.1130586210, phase: -0.0009408414),
        Term(d: 1, m: 0, mp: -2, f: -1, o: 0, amplitude: 0.1097591698, phase: -0.0039862645),
        Term(d: 2, m: 2, mp: -1, f: -1, o: 0, amplitude: 0.1089636863, phase: -0.0019009378),
        Term(d: 1, m: 1, mp: 1, f: 1, o: 0, amplitude: 0.1019376008, phase: -3.1409532672),
        Term(d: 0, m: 2, mp: -1, f: 1, o: 0, amplitude: 0.0953811182, phase: 0.0012209777),
        Term(d: 4, m: -2, mp: -1, f: 1, o: 2, amplitude: 0.0937514036, phase: -0.4213023469),
        Term(d: 0, m: 0, mp: 4, f: -1, o: 0, amplitude: 0.0916095185, phase: -3.1408413168)
    ]
    // swiftlint:enable comma line_length
}
